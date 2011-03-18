class IndexController < ApplicationController
  def index

    @type_to_i = { 'recent' => 1, 'today' => 2, 'yesterday' => 3, 'week' => 4 }
    @type_to_s = @type_to_i.invert

    categories = Category.find(:all, :order => "parent_cid, id")

    @cid_to_i = {}
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
      @cid_to_i[category.ascii_name] = cid
    end
    @cid_to_s = @cid_to_i.invert

    @cid = params[:cid].to_s
    @type = params[:type].to_s

    if @cid.match(/\D/) and @cid_to_i.key?(@cid)
      @cid = @cid_to_i[@cid]
    else
      @cid = @cid.to_i
    end
    if !@cid_to_s.key?(@cid)
      @cid = 1
    end

    if @type.match(/\D/) and @type_to_i.key?(@type)
      @type = @type_to_i[@type]
    else
      @type = @type.to_i
    end
    if !@type_to_s.key?(@type)
      @type = 1
    end

  end
end
