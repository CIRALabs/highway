class CmsVoucher < Voucher

  def voucher_type
    "cms_voucher"
  end

  def sign!(today: DateTime.now.utc)
    cv = Chariwt::Voucher.new
    cv.assertion    = 'logged'
    cv.serialNumber = serial_number
    cv.voucherType  = :time_based
    cv.nonce        = nonce
    cv.createdOn    = today
    cv.expiresOn    = expires_on
    cv.signing_cert   = MasaKeys.masa.masakey
    if owner.certificate
      cv.pinnedDomainCert = owner.certder
    else
      cv.pinnedPublicKey  = owner.pubkey_object
    end

    # pkcs_sign returns Base64, decode it again.
    self.as_issued = Base64.strict_decode64(cv.pkcs_sign(MasaKeys.masa.masaprivkey))
    notify_voucher!
    save!
    self
  end
end
