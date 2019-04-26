class CoseVoucher < Voucher

  def voucher_type
    "cose_voucher"
  end


  def sign!(today: DateTime.now.utc)
    cv = Chariwt::Voucher.new
    cv.assertion    = 'logged'
    cv.serialNumber = serial_number
    cv.voucherType  = :time_based
    cv.nonce        = nonce
    cv.createdOn    = today
    cv.expiresOn    = expires_on
    cv.signing_cert   = signing_cert
    if owner.certificate
      cv.pinnedDomainCert = owner.certder
    else
      cv.pinnedPublicKey  = owner.pubkey_object
    end

    self.as_issued = cv.cose_sign(MasaKeys.masa.masaprivkey)

    if false
      # verify that key validates contents
      valid = Chariwt::Voucher.from_cbor_cose(as_issued, signing_cert)
    end

    notify_voucher!
    save!
    self
  end

end
