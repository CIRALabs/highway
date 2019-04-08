class TranslateIDevIDCertToPubKey < ActiveRecord::Migration[5.2]
  def up
    Device.all.each {|a|
      if a.idevid_cert.blank? and !a.pub_key.blank? and a.pub_key.include?("BEGIN CERTIFICATE")
        puts "  ..converting #{a.id}"
        a.idevid_cert = a.pub_key
        a.set_public_key(a.certificate.public_key)
        a.save!
      end
    }
  end
end
