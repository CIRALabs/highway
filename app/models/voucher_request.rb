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

  def name
    "voucherreq_#{self.id}"
  end

  def proximity?
    "proximity" == details["assertion"]
  end

  def savefixturefw(fw)
    voucher.savefixturefw(fw) if voucher
    owner.savefixturefw(fw)   if owner
    save_self_tofixture(fw)
  end

  def signing_public_key
    unless signing_key.blank?
      @signing_public_key ||= OpenSSL::PKey.read(Base64.urlsafe_decode64(signing_key))
    end
  end

  def populate_explicit_fields(hash = details)
    self.device_identifier = hash["serial-number"]
    self.device            = Device.find_by_number(device_identifier)
    self.nonce             = hash["nonce"]
  end

  def issue_voucher(effective_date = Time.now)

    # at a minimum, this must be before a device that belongs to us!
    unless device
      DeviceNotifierMailer.voucher_notissued_email(self, :notmydevice).deliver
      return nil,:notmydevice
    end

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

    voucher = generate_voucher(owner, device, effective_date, nonce)
    self.voucher = voucher
    save!
    return voucher,:ok
  end

end
