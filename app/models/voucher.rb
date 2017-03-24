class Voucher < ActiveRecord::Base
  belongs_to :device

  def jsonhash(today = DateTime.utc.now)
    h2 = Hash.new
    h2["nonce"]      = nonce
    h2["created-on"] = created_at
    h2["device-identifier"] = device.eui64
    h2["assertion"]         = "logged"
    h2["owner"]             = "foo" # self.owner.der_spki.to_base64

    # return it all.
    h1 = Hash.new
    h1["ietf-voucher:voucher"] = h2
    h1
  end
end
