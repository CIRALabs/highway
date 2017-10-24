class Owner < ActiveRecord::Base
  include FixtureSave
  has_many :vouchers
  has_many :voucher_requests

  def self.decode_pem(pemstuff)
    Chariwt::Voucher.decode_pem(pemstuff)
  end

  def decode_pem(pemstuff)
    Chariwt::Voucher.decode_pem(pemstuff)
  end

  def certder
    if self.certificate
      @cert ||= OpenSSL::X509::Certificate.new(decode_pem(self.certificate))
    else
      @cert = ""
    end
  end

  def pubkey_object
    unless self[:pubkey].blank?
      OpenSSL::PKey.read(Chariwt::Voucher.decode_pem(self[:pubkey]))
    end
  end

  # this returns a PKey Object, while pubkey belows is the base64 version.
  def pubkey_from_cert
    @public_object ||= if certificate
                      certder.public_key
                    elsif self[:pubkey]
                      pubkey_object
                    end
  end

  def pubkey
    if self[:pubkey].blank? and !self.certificate.blank?
      self.pubkey = Base64.urlsafe_encode64(pubkey_from_cert.to_der)
      save!
    end
    self[:pubkey]
  end

  def subject
    certder.owner
  end

  def registrarID
    der = pubkey_from_cert.to_der
    rawpubkey = nil
    asn1 = OpenSSL::ASN1.decode(der)
    asn1.value.each {|v|
      if v.tag == 3
        rawpubkey = v.value
      end
    }
    return nil unless rawpubkey
    return Digest::SHA1.digest(rawpubkey)
  end

  def self.find_by_public_key(base64key)
    decoded = decode_pem(base64key)

    # if failed to dceode, then do not look anything up.
    return nil unless decoded

    # must canonicalize the key by decode and then der.
    begin
      # try decoding it as a public key
      pkey = OpenSSL::PKey.read(decoded)
    rescue OpenSSL::PKey::PKeyError
      pkey = nil
    end

    unless pkey
      begin
        cert = OpenSSL::X509::Certificate.new(decoded)
        pkey = cert.public_key
      rescue OpenSSL::X509::CertificateError
        return nil
      end
    end

    # use explicit base64 encoding to avoid BEGIN/END construct of to_pem.
    pkey_pem = Base64.urlsafe_encode64(pkey.to_der)

    key = where(pubkey: pkey_pem).take || create(pubkey: pkey_pem)
    if cert
      key.certificate = cert.to_pem
    end
    key.save
    key
  end

end
