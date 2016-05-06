class DevicesController < ApplicationController
  active_scaffold :device do |config|
    config.columns = [ :hostid, :customer, :hostname ]
  end

end
