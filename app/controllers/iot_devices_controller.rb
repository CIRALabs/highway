class IotDevicesController < ApiController

  # /send_new_device_notification
  def new
    @clientpem = capture_client_certificate

    unless @clientpem
      logger.info "no client certificate provided"
      head 403, text: "invalid authorization, no certificate provided"
      return
    end

    # now locate the (gateway) device based upon the certificate provided.
    @device = Device.get_router_by_identity(@clientpem)
    unless @device
      logger.info "device with provided certificate not found"
      head 404, text: "authorization device is unknown"
      return
    end

    tokens  = params[:registrationTokens]
    if tokens.nil? or tokens.empty? or tokens.first.blank?
      head 403, text: "No tokens included"
      return
    end

    device  = params[:hardwareAddress]
    @device.notify_new_device_message(tokens, device)

    head 200, text: "new device notification sent"
  end

  def analysis_complete
  end

end
