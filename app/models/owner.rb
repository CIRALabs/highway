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

  # returns an OpenSSL certificate object made by decoding the stored PEM.
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
    certder.subject
  end

  def simplename
    "owner_#{id}"
  end

  def name
    @name ||= subject.to_s
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

  def registrarID_base64
    Base64.strict_encode64(registrarID)
  end

  def self.decode_to_cert(encoded)
    begin
      cert = OpenSSL::X509::Certificate.new(Base64.decode64(encoded))
    rescue OpenSSL::X509::CertificateError
      cert = OpenSSL::X509::Certificate.new(Base64.urlsafe_decode64(encoded))
    end
    return cert
  end

  def self.find_or_create_by_base64_certificate(encoded)
    cert = decode_to_cert(encoded)
    if cert
      find_or_create_by_public_key_obj(cert.public_key, cert)
    end
  end

  def self.find_by_base64_certificate(encoded)
    cert = decode_to_cert(encoded)
    byebug
    if cert
      find_by_public_key_obj(cert.public_key, cert)
    end
  end

  def self.find_by_public_key_obj(pkey, cert = nil)
    # use explicit base64 encoding to avoid BEGIN/END construct of to_pem.
    pkey_pem = Base64.urlsafe_encode64(pkey.to_der)

    key = where(pubkey: pkey_pem).take
    return nil unless key

    byebug
    if cert and key.certificate.blank?
      key.certificate = cert.to_pem
    end
    key.save
    key
  end

  def self.find_or_create_by_public_key_obj(pkey, cert = nil)
    # use explicit base64 encoding to avoid BEGIN/END construct of to_pem.
    pkey_pem = Base64.urlsafe_encode64(pkey.to_der)

    key = where(pubkey: pkey_pem).take || create(pubkey: pkey_pem)
    if cert and key.certificate.blank?
      key.certificate = cert.to_pem
    end
    key.save
    key
  end

  # this will take a DER encoded Public key *OR* certificate,
  # attempting to turn it into an object, and then finding
  # the public key inside to look up the owner.
  def self.find_by_encoded_public_key(encoded)
    # if failed to decode, then do not look anything up.
    return nil unless encoded

    cert = nil
    # must canonicalize the key by decode and then der.
    begin
      # try decoding it as a public key
      pkey = OpenSSL::PKey.read(encoded)
    rescue OpenSSL::PKey::PKeyError
      pkey = nil
    end

    unless pkey
      begin
        cert = OpenSSL::X509::Certificate.new(encoded)
        pkey = cert.public_key
      rescue OpenSSL::X509::CertificateError
        return nil
      end
    end

    find_or_create_by_public_key_obj(pkey, cert)
  end

end
