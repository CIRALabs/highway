class Owner < ActiveRecord::Base
  include FixtureSave
  has_many :vouchers
  has_many :voucher_requests

  def certder
    @cert ||= OpenSSL::X509::Certificate.new(self.certificate)
  end

end
