class DeviceNotifierMailer < ApplicationMailer

  def voucher_issued_email(voucher)
    @owner = voucher.owner
    @device= voucher.device
    @hostname = SystemVariable.string(:hostname)
    mail(to: ENV['USER'], subject: "New voucher issued for #{@device.name}")
  end

  def voucher_notissued_email(voucher_req, reason)
    @voucher_req = voucher_req
    @hostname = SystemVariable.string(:hostname)
    @reason   = reason
    mail(to: ENV['USER'], subject: "Did not issue voucher")
  end

  def invalid_voucher_request(request)
    @originating_ip = request.env["REMOTE_ADDR"]
    @hostname = SystemVariable.string(:hostname)
    mail(to: ENV['USER'], subject: "Invalid voucher request")
  end

end
