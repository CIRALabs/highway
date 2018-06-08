class CoseVoucherRequest < VoucherRequest

  def self.from_cbor_cose(token, pubkey = nil)
    from_cbor_cose(StringIO.new(token), pubkey)
  end

  def self.from_cbor_cose_io(iotoken, pubkey = nil)
    iotoken = StringIO.new(iotoken.read)
    token   = iotoken.read
    iotoken.pos = 0  # rewind.
    begin
      vr = Chariwt::VoucherRequest.from_cbor_cose_io(iotoken, pubkey)
    rescue Chariwt::Voucher::MissingPublicKey
      raise InvalidVoucherRequest
    end

    unless vr
      raise InvalidVoucherRequest
    end
    hash = vr.sanitized_hash
    voucher = create(details: hash, voucher_request: token)
    #voucher.request = vr
    voucher.populate_explicit_fields(vr.vrhash)

    voucher.extract_prior_signed_voucher_request(vr)
    voucher.signing_key = pubkey
    voucher.lookup_owner

    voucher
  end

  def pledge_cbor
    @pledge_cbor ||= prior_voucher_request.inner_attributes
  end

  def lookup_owner
    proximity = pledge_cbor["proximity-registrar-cert"]
    if proximity
      # it is already binary, no pem/base64 decoding needed.
      self.owner = Owner.find_by_public_key(proximity)
    end
    self.owner
  end

  def prior_voucher_request
    @prior_voucher_request ||= Chariwt::VoucherRequest.from_cose_withoutkey(pledge_request)
  end

  def extract_prior_signed_voucher_request(cvr)
    self.pledge_request    = cvr.priorSignedVoucherRequest

    if cvr.signing_cert and prior_voucher_request.signing_cert
      self.prior_signing_key = Base64.urlsafe_encode64(prior_voucher_request.try(:signing_cert).public_key.to_der)
    end
  end

end
