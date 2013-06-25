class ServersTags < ActiveRecord::Base
  belongs_to :server
  belongs_to :tag
end
