class VoucherRequest < ApplicationRecord
  belongs_to :voucher
  belongs_to :owner
  belongs_to :device
  include FixtureSave

  attr_accessor :tls_clientcert, :prior_voucher_request

  class InvalidVoucherRequest < Exception; end
  class MissingPublicKey < Exception; end

  def self.from_json(json, artifact)
    vr = create(details: json, voucher_request: artifact)
    vr.populate_explicit_fields
    vr
  end

  def self.from_json_jose(token, json = nil)
    jsonresult = Chariwt::VoucherRequest.from_jose_json(token)
    unless jsonresult
      raise InvalidVoucherRequest
    end
    return from_json(jsonresult.inner_attributes, token)
  end

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

  def name
    "voucherreq_#{self.id}"
  end
  def savefixturefw(fw)
    voucher.savefixturefw(fw) if voucher
    owner.savefixturefw(fw)   if owner
    save_self_tofixture(fw)
  end

  def prior_voucher_request
    @prior_voucher_request ||= Chariwt::VoucherRequest.from_pkcs7_withoutkey(pledge_request)
  end

  def pledge_json
    @pledge_json ||= prior_voucher_request.inner_attributes
  end

  def lookup_owner
    proximity = pledge_json["proximity-registrar-cert"]
    if proximity
      self.owner = Owner.find_by_public_key(proximity)
    end
    self.owner
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

  def signing_public_key
    unless signing_key.blank?
      @signing_public_key ||= OpenSSL::PKey.read(Base64.urlsafe_decode64(signing_key))
    end
  end

  def populate_explicit_fields
    self.device_identifier = details["serial-number"]
    self.device            = Device.find_by_number(device_identifier)
    self.nonce             = details["nonce"]
  end

  def issue_voucher(effective_date = Time.now)
    # at a minimum, this must be before a device that belongs to us!
    return nil,:notmydevice unless device

    # must have an owner!
    return nil,:ownerunknown unless owner

    # here we have to validate the prior signed voucher
    return nil,:ownermisidentified unless owner.pubkey == signing_key

    # validate that the signature on the prior-signed-voucher-request
    # is from the key which was assigned to the device.
    return nil,:rawvoucherinvalid unless device.signing_key?(prior_voucher_request.signing_cert)

    # XXX if there is another valid voucher for this device, it must be for
    # the same owner.

    ## XXX what other kinds of validation belongs here?

    voucher = Voucher.create_voucher(owner, device, effective_date, nonce)
    self.voucher = voucher
    save!
    return voucher,:ok
  end

end
