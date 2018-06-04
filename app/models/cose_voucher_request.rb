class CoseVoucherRequest < VoucherRequest

  def cose_extract_prior_signed_voucher_request(cvr)
    self.pledge_request    = cvr.priorSignedVoucherRequest

    if cvr.signing_cert
      self.prior_signing_key = Base64.urlsafe_encode64(prior_voucher_request.signing_cert.public_key.to_der)
    end

    lookup_owner
  end

end
