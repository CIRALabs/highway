class Owner < ActiveRecord::Base
  has_many :vouchers
end
