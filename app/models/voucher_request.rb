class VoucherRequest < ApplicationRecord
  belongs_to :voucher
  belongs_to :owner
  belongs_to :device
  include FixtureSave

  class InvalidVoucherRequest < Exception; end
  class MissingPublicKey < Exception; end

  def self.from_json(json, token)
    vr = create(details: json, raw_request: token)
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
    jsonresult = Chariwt::VoucherRequest.from_pkcs7(token)
    # on MASA, voucher requests MUST always be signed
    unless jsonresult
      raise InvalidVoucherRequest
    end
    return from_json(jsonresult.inner_attributes, true)
  end

  def name
    "voucherreq_#{self.id}"
  end
  def savefixturefw(fw)
    voucher.savefixturefw(fw) if voucher
    owner.savefixturefw(fw)   if owner
    save_self_tofixture(fw)
  end

  def populate_explicit_fields
    self.device_identifier = details["serial-number"]
    self.device            = Device.find_by_number(device_identifier)
    self.nonce             = details["nonce"]
    self.owner = Owner.find_by_public_key(details["pinned-domain-cert"])
  end

  def issue_voucher(effective_date = Time.now)
    # at a minimum, this must be before a device that belongs to us!
    return nil unless device

    # must have an owner!
    return nil unless owner

    # XXX if there is another valid voucher for this device, it must be for
    # the same owner.

    ## XXX what other kinds of validation belongs here?

    voucher = Voucher.create(owner: owner,
                             device: device,
                             nonce: nonce)
    unless nonce
      voucher.expires_on = effective_date + 14.days
    end
    voucher.pkcs_sign!(effective_date)
  end

end
