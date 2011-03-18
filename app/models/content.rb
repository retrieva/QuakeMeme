require 'json'
class Content < ActiveRecord::Base
  belongs_to :category

  CONTENT_TYPE_RECENT = 1
  CONTENT_TYPE_TODAY = 2
  CONTENT_TYPE_YESTERDAY = 3
  CONTENT_TYPE_WEEK = 4

  def self.get_contents(catid, ctype)
    cat = Category.find_by_id(catid)
    content = Content.find(:first, :conditions => {:content_type => ctype, :category_id => catid})
    return {} unless cat && ctype && content
    ret = {:pages => [], :type => ctype, :category_name => cat.name}

    pagesjson = JSON.parse(content.json)
    pages = Page.find(:all, :conditions => {:spam => false, :url => pagesjson.map{|a| a[1]}})
    pagesjson.each do |p|
      page = pages.select{|a| a.url == p[1]}[0]
      if page
        tmp = {
          :count => p[0],
          :url => p[1],
          :id => page.id,
          :title => page.title || "",
          :description => page.description || "",
          :image_url => JSON.parse(page.image_url.gsub(/\\/, "").gsub(/"\[/, "[").gsub(/\]"/, "]") || "[]"),
        }
        ret[:pages].push(tmp)
      end
    end
    return ret
  end
  

end
