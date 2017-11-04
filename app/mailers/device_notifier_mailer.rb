class DeviceNotifierMailer < ApplicationMailer

  def voucher_issued_email(user, voucher)
    @user = user
    @url  = 'http://example.com/login'
    @owner = voucher.owner
    @device= voucher.device
    @hostname = SystemVariable.string(:hostname)
    mail(to: ENV['USER'], subject: "New voucher issued for #{@device.name}")
  end

end
