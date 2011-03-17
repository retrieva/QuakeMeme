class Category < ActiveRecord::Base
  has_one :content
end
