class IndexController < ApplicationController
  def index
    @cid = params[:cid].to_i
    @type = 1
    #@type = params[:type].to_i

    categories = Category.find(:all, :order => "parent_cid, id")

    @cattree = []
    key_to_index = {}
    categories.each do |category|
      cid = category.id
      pid = category.parent_cid
      if pid == 0
        key_to_index[cid] = @cattree.length
        @cattree << {
          :id => cid,
          :name => category.name,
          :children => []
        }
      else
        @cattree[key_to_index[pid]][:children] << {
          :id => cid,
          :name => category.name
        }
      end
    end

  end
end
