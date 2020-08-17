class IotDevicesController < ApiController

  # /send_new_device_notification
  def new
    @clientpem = capture_client_certificate

    unless @clientpem
      head 403, text: "invalid authorization, no certificate provided"
      return
    end

    # now locate the (gateway) device based upon the certificate provided.
    @device = Device.get_router_by_identity(@clientpem)
    unless @device
      head 404, text: "authorization device is unknown"
    end

    head 200, text: "new device notification sent"
  end

  def analysis_complete
  end

end
