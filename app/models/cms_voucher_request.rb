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
    voucher.signing_key = Base64.urlsafe_encode64(cvr.signing_cert.public_key.to_der)
    voucher.save!
    voucher
  end

  def self.from_cbor_cose(token, pubkey = nil)
    vr = Chariwt::VoucherRequest.from_cbor_cose(token, pubkey)
    unless vr
      raise InvalidVoucherRequest
    end
    hash = vr.sanitized_hash
    voucher = create(details: hash, voucher_request: token)
    #voucher.request = vr
    voucher.populate_explicit_fields(vr.vrhash)
    voucher.extract_prior_signed_voucher_request(vr)

    voucher
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
