class Voucher < ActiveRecord::Base
  belongs_to :device
  belongs_to :owner

  def jsonhash(today = DateTime.utc.now)
    h2 = Hash.new
    h2["nonce"]      = nonce
    h2["created-on"] = created_at
    h2["device-identifier"] = device.eui64
    h2["assertion"]         = "logged"
    h2["owner"]             = Base64.strict_encode64(self.owner.certder.to_der)

    # return it all.
    h1 = Hash.new
    h1["ietf-voucher:voucher"] = h2
    h1
  end

  def signed_voucher(today = DateTime.utc.now)
    serialized_json = jsonhash(today).to_json

    signed = OpenSSL::PKCS7.sign(HighwayKeys.ca.rootkey,
                                 HighwayKeys.ca.rootprivkey,
                                 serialized_json)
    signed
  end
end
