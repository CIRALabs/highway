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
      head 404, text: reason.to_s
    end
  end
end
