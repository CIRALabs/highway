class VoucherRequest < ApplicationRecord
  belongs_to :voucher
  belongs_to :owner
  belongs_to :device
  include FixtureSave

  class InvalidVoucherRequest < Exception; end
  class MissingPublicKey < Exception; end

  def self.from_json_jose(token)

    # first extract the public key so that it can be used to verify things.
    unverified_token = JWT.decode token, nil, false
    json0 = unverified_token[0]
    pkey  = nil
    if json0['ietf-voucher:voucher']
      voucher=json0['ietf-voucher:voucher']
      if voucher["pinned-domain-cert"]
        pkey_der = Base64.urlsafe_decode64(voucher["pinned-domain-cert"])
        pkey = OpenSSL::PKey::EC.new(pkey_der)
      end
    end
    raise VoucherRequest::MissingPublicKey unless pkey

    decoded_token = JWT.decode token, pkey, true, { :algorithm => 'ES256' }
    json = decoded_token[0]
    vr = create(details: json)
    vr.populate_explicit_fields
    vr.owner      = Owner.find_by_public_key(vr.vdetails["pinned-domain-cert"])
    vr
  end

  def vdetails
    raise VoucherRequest::InvalidVoucherRequest unless details["ietf-voucher:voucher"]
    @vdetails ||= details["ietf-voucher:voucher"]
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
    self.device_identifier = vdetails["serial-number"]
    self.device            = Device.find_by_number(device_identifier)
    self.nonce             = vdetails["nonce"]
  end

end
