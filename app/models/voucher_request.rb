class VoucherRequest < ApplicationRecord
  belongs_to :voucher
  belongs_to :owner
  include FixtureSave

  class InvalidVoucherRequest < Exception; end

  def self.from_json_jose(token)
    decoded_token = JWT.decode token, nil, false
    json = decoded_token[0]
    vr = create(details: json)
    vr.populate_explicit_fields
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
    self.nonce             = vdetails["nonce"]
  end

end
