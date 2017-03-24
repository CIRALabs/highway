class DevicesController < ApplicationController
  before_filter :require_admin

  active_scaffold :device do |config|
    #config.columns = [ :eui64, :customer, :hostname ]
  end

end
