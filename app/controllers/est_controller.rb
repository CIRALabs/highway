class EstController < ApiController

  def requestvoucher
    binary_pkcs = Base64.decode64(request.body.read)
    @voucherreq = VoucherRequest.from_pkcs7(binary_pkcs)

    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    if clientcert_pem
      @voucherreq.tls_clientcert = clientcert_pem
    end
    @voucherreq.save!
    @voucher = @voucherreq.issue_voucher
    if @voucher
      json_response(@voucher.as_issued, :ok,
                    'application/pkcs7-mime; smime-type=voucher')
    else
      head 404
    end
  end
end
