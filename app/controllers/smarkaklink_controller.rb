require 'multipart_body'

# use of ActionController::Metal means that JSON parameters are
# not automatically parsed, which reduces cases of processing bad
# JSON when no JSON is acceptable anyway.
class SmarkaklinkController < ApiController

  def enroll
    clientcert  = nil
    @replytype  = request.content_type
    @clientcert = capture_client_certificate

    # params in application/json will get parsed automatically, no need
    # to do anything.
    # the posted certificate will in most cases be identical
    # to the TLS Client Certificate.
    # note: the lookup is by *PUBLIC KEY*, not certificate.


    if params[:cert]
      @owner = Owner.find_or_create_by_base64_certificate(params[:cert])

      @cert = @owner.sign_with_idevid_ca
      send_data @cert.to_der, :type => 'application/pkcs7'

    else
      capture_bad_request(msg: "enrollment failed for #{request.ip}, no certificate provided")
      head 406, text: "missing certificate"
    end
  end

  def provision
    ip = request.env["REMOTE_ADDR"]
    if devnum=params['switch-mac']
      @device = Device.find_by_number(devnum) || Device.find_by_second_eui64(devnum)
    end
    if !@device and devnum=params['wan-mac']
      devnum  = Device.canonicalize_eui64(devnum)
      @device = Device.find_by_number(devnum) || Device.find_by_second_eui64(devnum)
    end
    unless @device
      num = ''
      if $TOFU_DEVICE_REGISTER
        attrs = Hash.new
        attrs['register_ip'] = ip
        attrs['tofu_register'] = true
        @device = Device.create(eui64: Device.canonicalize_eui64(params['switch-mac']),
                      second_eui64: Device.canonicalize_eui64(params['wan-mac']),
                      obsolete: true)        # mark it has not valid until an admin makes it valid
        num = @device.id
        @device.extra_attrs.merge!(attrs)
        @device.save!
      end
      head 404, text: "device not known here #{num}"
      return
    end

    # found a device, collect the information about it!
    @device.update_from_smarkaklink_provision(params)
    @csr64 = params['csr']

    # now create a private certificate from this CSR.
    begin
      @device.sign_from_base64_csr(@csr64)
    rescue Device::CSRFailed => e
      params[:failed_message] = e.message
      capture_bad_request(msg: "CSR failed to be signed by CA in id\##{@device.id}",
                          params: params)

      @device.save!
      return
    end

    @device.save!
    logger.info "Enrolled #{@device.name} from #{ip}"

    tgzfile = @device.generate_tgz_for_shg
    unless tgzfile
      logger.info "Failed to generate tgz file"
      head 404
    else
      send_file tgzfile, :type => 'application/tar+gzip'
    end
  end

  def enrollstatus
    unless params['voucher']
      logger.info "A voucher is required to match device"
      head 406
      return
    end

    binary_pkcs = Base64.urlsafe_decode64(params['voucher'])

    @voucher = Voucher.find_by_issued_voucher(binary_pkcs)

    unless @voucher
      head 404, text: "unknown transaction ignored"
      return
    end

    @device = @voucher.device
    @device.extra_attrs['last_status'] = params['status']
    @device.extra_attrs['last_reason'] = params['reason']
    @device.save!
    head 200
  end


  private

  # not sure how/where to capture bad requests
  def capture_bad_request(msg: "", params: params)
    logger.info "Bad owner enrollment #{msg}: #{params}"
    head 406
  end

end
