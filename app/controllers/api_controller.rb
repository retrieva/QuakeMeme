require 'rubygems'
require 'json'

class ApiController < ApplicationController
  def get_contents
    cid = params[:cid]
    type = params[:type].to_i
    cat = Category.find_by_id(cid.to_i)
    content = Content.find(:first, :conditions => {:content_type => type, :category_id => cid})
    (render(:json => ["resource not found"], :status => :not_found ) and return) unless cat && type && content
    ret = {:pages => [], :type => type, :category_name => cat.name}

    pagesjson = JSON.parse(content.json)
    pagesjson.each do |p|
      page = Page.find_by_url(p[1])
      if page && !page.spam
        tmp = {
          :count => p[0],
          :url => p[1],
          :id => page.id,
          :title => page.title || "",
          :description => page.description || "",
          :image_url => page.image_url || "",
        }
        ret[:pages].push(tmp)
      end
    end

    render :json => ret, :callback => params[:callback]
  end
end
