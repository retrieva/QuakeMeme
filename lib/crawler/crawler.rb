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
require 'hpricot'
require 'kconv'

# Network
def http_get(u)
  begin
    uri = URI.parse(u)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 30
    http.read_timeout = 30
    http.start do |http_local|
      begin
        response = http_local.get(uri.path + "?" + uri.query)
        return response.body
      rescue Errno::ETIMEDOUT, TimeoutError, Timeout::Error, Exception
      end
    end
  rescue Errno::ETIMEDOUT, TimeoutError, Timeout::Error, Exception
  end
  return ''
end

# Sedue
def sedue_get(w)
  # TODO: AND query
  json = http_get("http://ec2-175-41-197-12.ap-northeast-1.compute.amazonaws.com/?format=json&q=(search:#{URI.encode(w)})?get=id,user,text,hashtags?sort=time:desc?from=0?to=10000")
  JSON.parse(json)
end

def url_normalize(u)
  u = u.split("#")[0]
  u
end

def sedue_url_get(w)
  h = {}
  json = sedue_get(w)
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

# Database
ActiveRecord::Base.establish_connection(
#:adapter  => "sqlite3",
#:database => "db/development.sqlite3",
  :adapter  => "mysql",
  :database => "quakememe_production",
  :user => "root",
  :encoding => "utf8",
  :timeout  => 5000)

# HTML
def html_get_page_title(url)
  h = {}
  begin
    timeout(5) do
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

# Page
def add_page(url)
  u = Page.find(:first, :conditions => ["url = ?", url])
  return unless u.nil?
  h = html_get_page_title(url)
  p "title: #{h.inspect}"
  return if h.empty?
  t = h['title']

  page = Page.new
  page.url = url
  page.spam = 0
  page.alive = (not (t.nil? or t.empty?))
  page.title = t
  page.description = h['description']
  page.image_url = h['images'].to_json
  page.save
end

def extract_description(page)
  raw = page.parser.to_s
  doc = Hpricot(raw)

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
  ret = str.toutf8.gsub(/\s/, "").split(//)[0...limit].join("")
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
if Category.all().empty?
  c = Category.new
  c.name = "Home"
  c.query = "http"
  c.save()
end
Category.all().each { |c|
  # [[count, url], [count, url], ...]
  entries = sedue_url_get(c.query)[0..29]
  entries.each { |e|
    cnt = e[0]
    url = e[1]
    add_page(url)
  }
  add_content(c, 1, entries)
  p Content.all()
  p Page.all()
}
