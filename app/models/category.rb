class Category < ActiveRecord::Base
  has_many :contents
end
