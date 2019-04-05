class TranslateIDevIDCertToPubKey < ActiveRecord::Migration[5.2]
  def change
    Device.all.each {|a|
      if a.idevid_cert.blank? and !a.pub_key.blank and a.pub_key.include?("BEGIN CERTIFICATE")
        a.idevid_cert = a.pub_key
        a.set_public_key(a.certificate.public_key)
      end
    }
  end
end
