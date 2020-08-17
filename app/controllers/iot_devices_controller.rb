class IotDevicesController < ApiController

  # /send_new_device_notification
  def new
    @clientcert = capture_client_certificate

    unless @clientcert
      head 403, text: "invalid authorization, no certificate provided"
      return
    end

    # now locate the (gateway) device based upon the certificate provided.
    @device = Device.get_router_by_identity(@clientcert)
  end

  def analysis_complete
  end

end
