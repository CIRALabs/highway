class VouchersController < ApplicationController
  before_filter :require_admin

  active_scaffold :voucher do |config|
    #config.columns = [ :hostid, :customer, :hostname ]
  end

end
