class OwnersController < ApplicationController
  before_filter :require_admin

  active_scaffold :owner do |config|
    #config.columns = [ :eui64, :customer, :hostname ]
  end
end
