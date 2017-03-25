class DevicesController < ApplicationController
  active_scaffold :device do |config|
    #config.columns = [ :eui64, :customer, :hostname ]
  end

end
