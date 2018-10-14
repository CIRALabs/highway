class CmsVoucherRequest < VoucherRequest
  def self.from_pkcs7(token, json = nil)
    # look to see if this is a byte-for-byte identical requestion
    if voucher = where(voucher_request: token).take
      return voucher
    end

    cvr = Chariwt::VoucherRequest.from_pkcs7_withoutkey(token)
    # on MASA, voucher requests MUST always be signed
    unless cvr
      raise InvalidVoucherRequest
    end
    voucher = from_json(cvr.inner_attributes, token)
    voucher.extract_prior_signed_voucher_request(cvr)
    voucher.populate_explicit_fields
    voucher.signing_key = Base64.urlsafe_encode64(cvr.signing_cert.public_key.to_der)

    voucher.lookup_owner
    voucher.validate_prior!
    voucher.save!
    voucher
  end

  def pledge_json
    @pledge_json ||= prior_voucher_request.inner_attributes
  end

  def lookup_owner
    proximity = pledge_json["proximity-registrar-cert"]
    if proximity
      cooked_key = Chariwt::Voucher.decode_pem(proximity)
      self.owner = Owner.find_by_public_key(cooked_key)
    end
    self.owner
  end

  def prior_voucher_request
    @prior_voucher_request ||= Chariwt::VoucherRequest.from_pkcs7_withoutkey(pledge_request)
  end

  def extract_prior_signed_voucher_request(cvr)
    self.pledge_request    = cvr.priorSignedVoucherRequest

    # save the decoded results into JSON bag.
    self.details["prior-signed-voucher-request"] = pledge_json
    if cvr.signing_cert
      self.prior_signing_key = Base64.urlsafe_encode64(prior_voucher_request.signing_cert.public_key.to_der)
    end

    lookup_owner
  end

  def generate_voucher(owner, device, effective_date, nonce, expires = nil)
    CmsVoucher.create_voucher(owner, device, effective_date, nonce, expires)
  end
end