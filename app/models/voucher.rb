require 'chariwt'

class Voucher < ActiveRecord::Base
  include FixtureSave
  belongs_to :device
  belongs_to :owner
  has_many   :voucher_requests

  class InvalidVoucher < Exception; end

  def serial_number
    device.serial_number
  end

  def device_identifier
    device.serial_number
  end

  def pkcs_sign!(today = DateTime.now.utc)
    cv = Chariwt::Voucher.new
    cv.assertion    = 'logged'
    cv.serialNumber = serial_number
    cv.voucherType  = :time_based
    cv.nonce        = nonce
    cv.createdOn    = today
    cv.expiresOn    = expires_on
    cv.signing_cert   = MasaKeys.ca.masakey
    if owner.certificate
      cv.pinnedDomainCert = owner.certder
    else
      cv.pinnedPublicKey  = owner.pubkey_object
    end

    self.as_issued = cv.pkcs_sign(MasaKeys.ca.masaprivkey)
    save!
    self
  end

  def self.create_voucher(owner, device, effective_date, nonce = nil, expires = nil)
    voucher = create(owner: owner,
                     device: device,
                     nonce: nonce)

    unless expires
      expires = effective_date + 14.days
    end
    unless nonce
      voucher.expires_on = expires
    end
    voucher.pkcs_sign!(effective_date)
    voucher
  end

  def self.from_json(json)
    raise Voucher::InvalidVoucher unless json["ietf-voucher:voucher"]

    vdetails = json["ietf-voucher:voucher"]
    self.nonce = vdetails["nonce"]
  end

  def name
    "voucher_#{self.id}"
  end
  def savefixturefw(fw)
    return if save_self_tofixture(fw)
    device.savefixturefw(fw) if device
    owner.savefixturefw(fw)  if owner
  end


end
