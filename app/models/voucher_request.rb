class VoucherRequest < ApplicationRecord
  belongs_to :voucher
  belongs_to :owner

  class InvalidVoucherRequest < Exception; end

  def self.from_json(json)

    vr = self.new
    raise VoucherRequest::InvalidVoucherRequest unless json["ietf-voucher:voucher"]
    vr.from_json(json)
  end

  def from_json(json)
    vdetails = json["ietf-voucher:voucher"]
    self.nonce = vdetails["nonce"]
    self
  end

end
