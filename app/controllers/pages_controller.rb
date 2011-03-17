class PagesController < ApplicationController
  before_filter :require_admin

  active_scaffold :page
  layout "activescaffold"
end
