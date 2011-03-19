class IndexController < ApplicationController
  def index
    categories = Category.find(:all, :order => "parent_cid, id")

    @category_to_i = {}
    @cattree = []
    id_to_index = {}
    id_to_index2 = {}
    id_to_obj = {}
    categories.each do |category|
      cid = category.id
      pid = category.parent_cid
      obj = {
        :id => cid,
        :name => category.name,
        :ascii_name => category.ascii_name,
        :children => [],
      }
      id_to_obj[cid] = obj
      # 親
      if pid == 0
        id_to_index[cid] = @cattree.length
        @cattree << obj
      else
        pidx = id_to_index[pid]
        # 子
        if !id_to_index2[pid]
          id_to_index[cid] = pidx
          id_to_index2[cid] = @cattree[pidx][:children].length
          @cattree[pidx][:children] << obj
        # 孫
        else
          @cattree[pidx][:children][id_to_index2[pid]][:children] << obj
        end
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
    @current_title = id_to_obj[@cid].name

  end
end
