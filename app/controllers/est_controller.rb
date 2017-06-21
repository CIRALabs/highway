class EstController < ApiController

  def requestvoucher
    @voucherreq = VoucherRequest.from_json_jose(request.body.read)

    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    if clientcert_pem
      @voucherreq.tls_clientcert = clientcert_pem
    end
    @voucherreq.save!
    @voucher = @voucherreq.issue_voucher
    json_response(@voucher, :ok)
  end
end
