class UnsignedVoucherRequest < CmsVoucherRequest
  def generate_voucher(owner, device, effective_date, nonce, expires = nil)
    CmsVoucher.create_voucher(owner, device, effective_date, nonce, expires)
  end
end
