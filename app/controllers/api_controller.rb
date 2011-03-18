require 'rubygems'
require 'json'

class ApiController < ApplicationController
  def get_contents
    # read from cache
    cache_key = "qm_api_cache_#{params[:cid]}_#{params[:type]}"
    begin
      cache_val = Rails.cache.read(cache_key)
    rescue MemCacheError
      cache_val = nil
    rescue
      cache_val = nil
    end

    # check cache-miss or memcached is down
    if cache_val.nil?
      # generate new json
      json = Content.get_contents(params[:cid].to_i, params[:type].to_i)

      # write to cache with expiration
      begin
        Rails.cache.write(cache_key, json, :expires_in => 1.minute) unless (json.nil? or json.empty?)
      rescue MemCacheError
      rescue
      end
    else
      json = cache_val
    end

    # show
    if json.empty?
      render(:json => ["resource not found"], :status => :not_found )
    else
      render :json => json, :callback => params[:callback]
    end
  end
end
