class DevicesController < ApplicationController
  before_action :require_admin

  def index
    if params[:pub_key]
      dev = Device.where(:pub_key => params[:pub_key]).take
      if dev
        head 201, :location => url_for(dev)
      end
    end
  end


end
