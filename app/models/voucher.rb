require 'chariwt'

class Voucher < ActiveRecord::Base
  include FixtureSave
  belongs_to :device
  belongs_to :owner
  has_many   :voucher_requests

  class InvalidVoucher < Exception; end

  scope :creation_order, -> { order('created_at DESC') }

  def serial_number
    device.serial_number
  end

  def device_identifier
    device.serial_number
  end

  def notify_voucher!
    DeviceNotifierMailer.voucher_issued_email(self).deliver
  end

  def signing_cert
    MasaKeys.masa.masakey
  end

  def self.create_voucher(owner, device, effective_date, nonce = nil, expires = nil)
    voucher = create(owner: owner,
                     device: device,
                     nonce: nonce)

    # assign the ownership.
    device.owner = owner
    device.save!

    unless expires
      expires = effective_date + 14.days
    end
    unless nonce
      voucher.expires_on = expires
    end

    voucher.sign!(effective_date)
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
