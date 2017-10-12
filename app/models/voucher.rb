require 'chariwt'

class Voucher < ActiveRecord::Base
  include FixtureSave
  belongs_to :device
  belongs_to :owner
  has_many   :voucher_requests

  class InvalidVoucher < Exception; end

  def jsonhash(today = DateTime.utc.now)
    h2 = Hash.new
    h2["nonce"]      = nonce
    h2["created-on"] = created_at
    h2["device-identifier"] = device.eui64
    h2["assertion"]         = "logged"

    if(owner.try(:certder))
      h2["owner"]           = Base64.strict_encode64(self.owner.certder.to_der)
    end

    # return it all.
    h1 = Hash.new
    h1["ietf-voucher:voucher"] = h2
    h1
  end

  def pkcs7_signed_voucher(today = DateTime.now.utc)
    serialized_json = jsonhash(today).to_json

    signed = OpenSSL::PKCS7.sign(HighwayKeys.ca.rootkey,
                                 HighwayKeys.ca.rootprivkey,
                                 serialized_json)
    signed
  end

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
