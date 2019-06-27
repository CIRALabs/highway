# -*- ruby -*-

namespace :shg do

  desc "Create the contents for a QR code for a given PRODUCTID="
  task :dpp_pledge => :environment do
    productid = ENV['PRODUCTID']

    device = Device.find_by_number(productid.downcase)
    if device
      STDERR.puts "Found product #{device.id}"
      puts device.dppstring
    else
      STDERR.puts "No product found with ID=#{productid}"
    end
  end

  desc "Mark a device PRODUCTID= as being valid for provisioning"
  task :valid => :environment do

    productid = ENV['PRODUCTID']
    device = Device.find_obsolete_by_eui64(productid)
    if device
      device.activated!
      puts "Marked #{device.id} #{device.notes} as active"
      if device.extra_attrs
        puts "Activated from #{device.extra_attrs['register_ip'] || "unknown"}"
      end
    else
      STDERR.puts "Device not found"
    end
  end

end
