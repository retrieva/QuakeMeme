class IndexController < ApplicationController
  def index
    categories = Category.find(:all, :order => "parent_cid, id")

    @category_to_i = {}
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
          :ascii_name => category.ascii_name,
          :children => [],
        }
      else
        @cattree[key_to_index[pid]][:children] << {
          :id => cid,
          :name => category.name,
          :ascii_name => category.ascii_name,
        }
      end
      @category_to_i[category.ascii_name] = cid
    end
    @category_to_s = @category_to_i.invert

    category = params[:category].to_s
    if @category_to_i.key?(category)
      @cid = @category_to_i[category]
    else
      @cid = 1
    end
    @type = params[:type].to_i

  end
end
