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
    voucher.validated=false
    voucher.raw_request = Base64.urlsafe_encode64(token)
    #voucher.request = vr
    voucher.extract_prior_signed_voucher_request(vr)
    voucher.populate_explicit_fields(voucher.prior_voucher_request.attributes)
    voucher.lookup_owner
    voucher.validate_prior!
    voucher
  end

  def pledge_cbor
    @pledge_cbor ||= prior_voucher_request.attributes
  end

  def lookup_owner
    proximity = pledge_cbor["proximity-registrar-cert"]
    if proximity
      # it is already binary, no pem/base64 decoding needed.
      self.owner = Owner.find_by_encoded_public_key(proximity)
    end
    self.owner
  end

  def prior_voucher_request
    case pledge_request
    when String
      @prior_voucher_request ||= Chariwt::VoucherRequest.from_cose_withoutkey(pledge_request)
    when Hash
      @prior_voucher_request ||= Chariwt::VoucherRequest.object_from_unsigned_json(pledge_request)
    end
  end

  def extract_prior_signed_voucher_request(cvr)
    self.pledge_request = cvr.priorSignedVoucherRequest
  end

  def generate_voucher(owner, device, effective_date, nonce, expires = nil)
    CoseVoucher.create_voucher(owner, device, effective_date, nonce, expires)
  end


end
