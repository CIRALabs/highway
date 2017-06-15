class EstController < ApiController

  def requestvoucher
    @vreq = JSON.parse(request.body.read)
    @voucherreq = VoucherRequest.from_json(@vreq)

    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    if clientcert_pem
      @voucherreq.tls_clientcert = clientcert_pem
    end
    @voucherreq.save!
    @voucher = @voucherreq.issue_voucher
    json_response(@voucher, :ok)
  end
end
