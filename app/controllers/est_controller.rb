class EstController < ApiController

  def requestvoucher
    binary_pkcs = Base64.decode64(request.body.read)
    @voucherreq = VoucherRequest.from_pkcs7(binary_pkcs)
    # keep the raw encoded request.
    @voucherreq.raw_request = request.body.read

    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    if clientcert_pem
      @voucherreq.tls_clientcert = clientcert_pem
    end
    @voucherreq.save!
    @voucher,reason = @voucherreq.issue_voucher
    if reason == :ok and @voucher
      json_response(@voucher.as_issued, :ok,
                    'application/pkcs7-mime; smime-type=voucher')
    else
      logger "no voucher issued, reason: #{reason.to_s}"
      head 404, text: reason.to_s
    end
  end

  def requestauditlog
    binary_pkcs = Base64.decode64(request.body.read)
    @voucherreq = VoucherRequest.from_pkcs7(binary_pkcs)
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
