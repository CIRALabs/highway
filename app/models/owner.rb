class Owner < ActiveRecord::Base
  has_many :vouchers

  def certder
    @cert ||= OpenSSL::X509::Certificate.new(self.certificate)
  end

end
