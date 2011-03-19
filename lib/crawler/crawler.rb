# -*- coding: utf-8 -*-
require 'rubygems'
require 'json'
require 'uri'
require 'net/http'
require 'active_record'
require 'active_support'
require 'app/models/category'
require 'app/models/page'
require 'app/models/content'
require 'mechanize'
require 'nokogiri'
require 'kconv'

$KCODE = 'u' if RUBY_VERSION < '1.9.0'

# Network
def http_get(u)
  begin
    uri = URI.parse(u)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 120
    http.read_timeout = 120
    http.start do |http_local|
      begin
        response = http_local.get(uri.path + "?" + uri.query)
        return response.body
      rescue Errno::ETIMEDOUT, TimeoutError, Timeout::Error, Exception => e
        p e
      end
    end
  rescue Errno::ETIMEDOUT, TimeoutError, Timeout::Error, Exception => e
    p e
  end
  return ''
end

# Sedue
def sedue_get(w)
  return {} if w.nil? or w.empty?
  # TODO: AND query
  w_separated = w.to_s.split("|")
  qstr = ""
  i = 0
  w_separated.each do |q|
    if i == 0
      qstr = "(search:#{q})"
    else
      qstr = "(" + qstr + "|(search:#{q}))"
    end
    i += 1
  end
  qstr = URI.encode(qstr)
  json = http_get("http://ec2-175-41-197-12.ap-northeast-1.compute.amazonaws.com/?format=json&q=#{qstr}?get=id,user,text,hashtags?sort=time:desc?from=0?to=10000")
  JSON.parse(json)
end

def url_normalize(u)
  u = u.split("#")[0]
  u
end

def sedue_url_get(w)
  h = {}
  json = sedue_get(w)
  return [] if json.nil? or json.empty?
  json['docs'].each { |d|
    URI.extract(d['fields']['text']).each { |u|
      next unless u.include?("http")
      next if u.length < 10
      next if u[0..3] != "http"
      u = url_normalize(u)
      if h.has_key? u
        h[u] = h[u] + 1
      else
        h[u] = 1
      end
    }
  }
  a = []
  h.each { |k, v| a << [v, k] }
  a.sort!.reverse!
  return a
end

# HTML/HTTP
def html_get_page_title(url)
  h = {}
  begin
    timeout(30) do
      agent = Mechanize.new
      page = agent.get(url)
      h['title'] = page.title.toutf8
      h['images'] = page.image_urls.to_json
      h['description'] = extract_description(page)
      return h
    end
  rescue Timeout::Error
    return {}
  rescue
    return {}
  end
end

def expand_url(orig_u)
  def expand_url_inner(url)
    begin
      uri = url.kind_of?(URI) ? url : URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 60
      http.read_timeout = 60
      http.start { |io|
        r = io.head(uri.path)
        return r['Location'] || uri.to_s
      }
    rescue Errno::ETIMEDOUT, TimeoutError, Timeout::Error, Exception => e
      return ''
    end
  end
  u = orig_u
  nretries = 0
  expanded = expand_url_inner(u)
  while (expanded != u && nretries <= 3)
    return u if expanded.empty?
    u = expanded
    expanded = expand_url_inner(u)
    nretries = nretries + 1
  end
  return (expanded.nil? or expanded.empty? or (not expanded.include?("http"))) ? orig_u : expanded
end

# Page
def set_page_contents(page)
  url = page.url
  h = html_get_page_title(url)
  return if h.empty?
  t = h['title']

  page.alive = (not (t.nil? or t.empty?))
  page.title = t
  page.description = h['description']
  page.image_url = h['images']
  page.original_url = expand_url(url)
end

def add_page(url)
  url = url.strip
  u = Page.find(:first, :conditions => ["url = ?", url])
  return unless u.nil?

  page = Page.new
  page.url = url
  set_page_contents(page)
  page.spam = 0
  page.save!
  puts "found: #{url}: #{page.original_url}"
end

def extract_description(page)
  raw = page.parser.to_s
  doc = Nokogiri(raw)

  # 1: <meta name="description" ...>があればそれを用いる
  tmp = doc.search("//meta[@name='description']").first
  return footcutter(tmp["content"]) if tmp && tmp["content"]

  # 2: <!-- google_ad_section_start(name=s1, weight=.9) --> <!-- google_ad_section_end -->で囲まれた箇所があればそれを用いる
  reg = /<!-- ?google_ad_section_start ?(?:\([^)]*\)|) ?-->(.*?)<!-- ?google_ad_section_end ?(?:\([^)]*\)|) ?-->/m
  tmp = []
  tmp2 = raw
  while tmp2.length > 0 do
    tmp3 = reg.match(tmp2)
    if tmp3
      tmp.push(tmp3[1].gsub(/<.*?>/, ""))
      tmp2 = tmp3.post_match
    else
      break
    end
  end
  return footcutter(tmp.join("")) unless tmp.empty?

  # 3: div.contents に囲まれた箇所があればそれを用いる
  tmp = doc.search("//div[@class='contents']")
  # 4: div.entry-body-text に囲まれた箇所があればそれを用いる
  tmp = doc.search("//div[@class='entry-body-text']") if tmp.empty?
  # 5: table#infobox に囲まれた箇所があればそれを用いる
  tmp = doc.search("//table[@id='infobox']") if tmp.empty?
  # 6: div.contents に囲まれた箇所があればそれを用いる
  tmp = doc.search("//p").select{|a| a["class"] == "entry-content" || ["class"] == "2par" || (a["class"].nil? && a["id"].nil?)} if tmp.empty?
  return footcutter(tmp.map{|a| a.to_s.gsub(/<.*?>/, "")}.join("")) unless tmp.empty?

  # else: あきらめる
  return ""
end

def footcutter(str, limit = 255)
  ret = str.toutf8.split(//)[0...limit].join("")
  ret.gsub!(/<[^>]*$/, "")
  ret
end

# Content
def add_content(category, content_type, entries)
  return if entries.nil? or entries.empty?
  cont = Content.find(:first,
                      :conditions =>
                      ["(category_id = ? and content_type = ?)",
                       category.id, content_type])
  if cont.nil?
    cont = Content.new
    cont.category_id = category.id
    cont.content_type = content_type
  end
  cont.json = entries.to_json
  cont.save()
end

# Category
def inner_crawl_category(cs)
  cs.each { |c|
    # [[count, url], [count, url], ...]
    entries = sedue_url_get(c.query)[0..29]
    entries.each { |e|
      cnt = e[0]
      url = e[1]
      add_page(url)
    }
    add_content(c, 1, entries)
    puts "crawled: #{c.name}"
  }
end

def crawl_top_category
  cs = Category.find(:all, :conditions => ["parent_cid = ?", 0])
  inner_crawl_category(cs)
end

def crawl_category
  if Category.all().empty?
    c = Category.new
    c.name = "Home"
    c.query = "http"
    c.save()
  end
  p Page.all().length
  inner_crawl_category(Category.all())
end

# Page
def crawl_page
  p Page.all().length
  Page.all().each { |p|
    set_page_contents(p)
    p.save!
    puts "found: #{p.url}: #{p.original_url}"
  }
  p Page.all().length
end

# main
def usage
  puts <<END
Usage:
  crawler.rb RAILS_ENV crawl_category
  crawler.rb RAILS_ENV crawl_top_category
  crawler.rb RAILS_ENV crawl_page
END
  exit
end

usage if ARGV.length != 2
p ARGV

rails_env = ARGV[0]
if rails_env == "development"
  ActiveRecord::Base.establish_connection(
   :adapter  => "sqlite3",
   :database => "db/development.sqlite3",
   :encoding => "utf8",
   :timeout  => 5000)
elsif rails_env == "production"
  ActiveRecord::Base.establish_connection(
   :adapter  => "mysql",
   :database => "quakememe_production",
   :user => "root",
   :encoding => "utf8",
   :timeout  => 5000)
else
  usage
end

cmd = ARGV[1]
if cmd == "crawl_category"
  crawl_category
elsif cmd == "crawl_top_category"
  crawl_top_category
elsif cmd == "crawl_page"
  crawl_page
else
  usage
end
