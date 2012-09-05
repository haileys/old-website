class Post < ActiveRecord::Base
  scope :recent, order("created_at DESC").limit(5)
end