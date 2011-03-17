class ContentsController < ApplicationController
  before_filter :require_admin

  active_scaffold :content
  layout "activescaffold"

end
