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
  json = http_get("http://ec2-175-41-197-12.ap-northeast-1.compute.amazonaws.com/?format=json&q=(search:#{URI.encode(w)})?get=id,user,text,hashtags?sort=time:desc?from=0?to=1000")
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
  :adapter  => "sqlite3",
  :database => "db/development.sqlite3",
  :timeout  => 5000)

# HTML
def html_get_page_title(url)
  begin
    timeout(5) do
      agent = Mechanize.new
      page = agent.get(url)
      return page.title
    end
  rescue Timeout::Error
    return ""
  rescue
    return ""
  end
end

# Page
def add_page(url)
  u = Page.find(:first, :conditions => ["url = ?", url])
  return unless u.nil?
  t = html_get_page_title(url)

  page = Page.new
  page.url = url
  page.spam = 0
  page.alive = (not (t.nil? or t.empty?))
  page.title = t
  page.description = ""
  page.image_url = ""
  page.save
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
