class DeviceNotifierMailer < ApplicationMailer

  def voucher_issued_email(voucher)
    @owner = voucher.owner
    @device= voucher.device
    @hostname = SystemVariable.string(:hostname)
    mail(to: ENV['USER'], subject: "New voucher issued for #{@device.name}")
  end

end
