class ContentsController < ApplicationController
  before_filter :require_admin

  active_scaffold :content do |config|
    config.list.per_page = 50
  end
  layout "activescaffold"

end
