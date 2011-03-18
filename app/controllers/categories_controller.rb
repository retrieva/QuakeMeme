class CategoriesController < ApplicationController
  before_filter :require_admin
  
  active_scaffold :category do |config|
    config.list.per_page = 50
    config.columns << :id
  end

  layout "activescaffold"


end
