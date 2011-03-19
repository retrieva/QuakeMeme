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
require 'lib/crawler/extractcontent'

$KCODE = 'u' if RUBY_VERSION < '1.9.0'
$TYPE_ALL = 1
$TYPE_ONE_HOUR = 2

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
def sedue_get(w, type)
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
  qstr = qstr + "?get=id,user,text,hashtags?sort=time:desc?from=0?to=10000"
  if type == $TYPE_ONE_HOUR
    qstr = qstr + "?time>=#{Time.now.to_i - 3600}"
  end
  qstr = URI.encode(qstr)
  url = "http://ec2-175-41-197-12.ap-northeast-1.compute.amazonaws.com/?format=json&q=#{qstr}"
  puts url
  json = http_get(url)
  JSON.parse(json)
end

def url_normalize(u)
  u = u.split("#")[0]
  u
end

def sedue_url_get(w, type)
  h = {}
  json = sedue_get(w, type)
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
def html_analyze(url)
  h = {}
  begin
    timeout(30) do
      agent = Mechanize.new
      page = agent.get(url)
      if page.class == Mechanize::Page
        desc, title = extract_description(page)
        h['title'] = title.size > 0 ? title : page.title.toutf8
        h['images'] = page.image_urls[0..2].to_json
        h['description'] = desc
      elsif page.class == Mechanize::File
        return { 'spam' => true } if page.code == 404
        h['title'] = page.filename
        h['images'] = "[]"
        h['description'] = ""
      end
      p h
      return h
    end
  rescue Mechanize::ResponseCodeError => e
    p e
    return { 'spam' => true }
  rescue Timeout::Error => e
    p e
    return { 'spam' => false }
  rescue => e
    p e
    return { 'spam' => true }
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
  h = html_analyze(url)
  if h.has_key? 'spam'
    page.spam = h['spam']
    puts "spam!: #{url}"
    return
  end

  t = h['title']
  page.alive = (not (t.nil? or t.empty?))
  page.title = t
  page.description = h['description']
  page.image_url = h['images']
  page.original_url = expand_url(url)
end

def add_page(url)
  url = url.strip
  return if url.nil? or url.empty?
  u = Page.find(:first, :conditions => ["url = ?", url])
  return unless u.nil?

  page = Page.new
  page.url = url
  page.spam = 0
  set_page_contents(page)
  page.save!
  puts "found: #{url}: #{page.original_url}"
end

def to_utf8(page)
  re = /charset="?([^\s"]*)/i
  cs = re.match(page)

  enc = if cs and cs[1].size > 0
    case cs[1].downcase[0].chr
    when 'u' then Kconv::UTF8
    when 'e' then Kconv::EUC
    when 's' then Kconv::SJIS
    else Kconv::AUTO
    end
  else
    Kconv::AUTO
  end

  enc == Kconv::UTF8 ? page : Kconv.kconv(page, Kconv::UTF8, enc)
end

def footcutter(str, limit = 255)
  ret = str.split(//)[0...limit].join("")
  ret.gsub!(/<[^>]*$/, "")
  ret
end

def extract_description(page)
  content = to_utf8(page.parser.to_s)
  body, title = ExtractContent::analyse(content)
  [footcutter(body), title]
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
    [$TYPE_ALL, $TYPE_ONE_HOUR].each { |type|
      entries = sedue_url_get(c.query, type)[0..29]
      entries.each { |e|
        cnt = e[0]
        url = e[1]
        add_page(url)
      }
      add_content(c, type, entries)
      puts "crawled: type=#{type}, name=#{c.name}"
    }
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
