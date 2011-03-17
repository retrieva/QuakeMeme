class CategoriesController < ApplicationController
  before_filter :require_admin
  
  active_scaffold :category do |config|
  end

  layout "activescaffold"


end
