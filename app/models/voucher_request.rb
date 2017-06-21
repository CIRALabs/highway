class VoucherRequest < ApplicationRecord
  belongs_to :voucher
  belongs_to :owner
  include FixtureSave

  class InvalidVoucherRequest < Exception; end

  def self.from_json(json)
    vr = self.new
    raise VoucherRequest::InvalidVoucherRequest unless json["ietf-voucher:voucher"]
    vr.from_json(json)
  end

  def from_json(json)
    vdetails = json["ietf-voucher:voucher"]
    populate_explicit_fields
    self
  end
  def vdetails
    @vdetails ||= details["ietf-voucher:voucher"]
  end

  def name
    "voucher\##{self.id}"
  end

  def populate_explicit_fields
    self.device_identifier = vdetails["serial-number"]
    self.nonce             = vdetails["nonce"]
  end

end
