class CategoriesController < ApplicationController
  before_filter :require_admin
  
  active_scaffold :category do |config|
    config.columns << :id
  end

  layout "activescaffold"


end
