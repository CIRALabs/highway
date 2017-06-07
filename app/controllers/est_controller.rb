class EstController < ApiController

  def requestvoucher
    @voucher = Voucher.new
    json_response(@voucher, :ok)
  end
end
