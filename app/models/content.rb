class Content < ActiveRecord::Base
  belongs_to :category

  CONTENT_TYPE_RECENT = 1
  CONTENT_TYPE_TODAY = 2
  CONTENT_TYPE_YESTERDAY = 3
  CONTENT_TYPE_WEEK = 4

  

end
