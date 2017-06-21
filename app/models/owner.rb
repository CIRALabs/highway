class Owner < ActiveRecord::Base
  include FixtureSave
  has_many :vouchers
  has_many :voucher_requests

  def certder
    @cert ||= OpenSSL::X509::Certificate.new(self.certificate)
  end

  def self.find_by_public_key(base64key)
    # must canonicalize the key by decode and then der.
    pkey_der = Base64.urlsafe_decode64(base64key)
    pkey = OpenSSL::PKey::EC.new(pkey_der)

    # use explicit base64 encoding to avoid BEGIN/END construct of to_pem.
    pkey_pem = Base64.urlsafe_encode64(pkey.to_der)

    key = where(certificate: pkey_pem).take || create(certificate: pkey_pem)
    key
  end

end
