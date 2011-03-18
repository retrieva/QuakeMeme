require 'rubygems'
require 'json'

class ApiController < ApplicationController
  def get_contents
    ret = Content.get_contents(params[:cid].to_i, params[:type].to_i)
    if ret.empty?
      render(:json => ["resource not found"], :status => :not_found )
    else
      render :json => ret, :callback => params[:callback]
    end
  end
end
