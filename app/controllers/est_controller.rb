class EstController < ApiController

  def requestvoucher

    clientcert = nil
    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    if clientcert_pem
      clientcert = OpenSSL::X509::Certificate.new(Chariwt::Voucher.decode_pem(clientcert_pem))
    end

    @replytype  = request.content_type

    case request.content_type
    when 'application/pkcs7-mime; smime-type=voucher-request',
         'application/pkcs7-mime',
         'application/voucher-cms+json'
      binary_pkcs = Base64.decode64(request.body.read)
      @voucherreq = CmsVoucherRequest.from_pkcs7(binary_pkcs)

    when 'application/voucher-cose+cbor'
      @voucherreq = CoseVoucherRequest.from_cbor_cose_io(request.body, clientcert)

    else
      head 406,
           text: "unknown voucher-request content-type: #{request.content_type}"
    end

    if clientcert_pem
      @voucherreq.tls_clientcert = clientcert_pem
    end

    # keep the raw encoded request.
    @voucherreq.raw_request = request.body.read
    @voucherreq.originating_ip = request.env["REMOTE_ADDR"]

    @voucherreq.save!
    #byebug
    @voucher,reason = @voucherreq.issue_voucher

    if reason == :ok and @voucher
      json_response(@voucher.as_issued, :ok, @replytype)
    else
      logger.error "no voucher issued for #{request.env["REMOTE_ADDR"]}, reason: #{reason.to_s}"
      head 404, text: reason.to_s
    end
  end

  def requestauditlog
    binary_pkcs = Base64.decode64(request.body.read)
    @voucherreq = CmsVoucherRequest.from_pkcs7(binary_pkcs)
    @device = @voucherreq.device
    @owner  = @voucherreq.owner

    if @device.device_owned_by?(@owner)
      json_response(@device.audit_log, :ok,
                    'application/json')
    else
      head 404, text: 'invalid device'
    end
  end

end
