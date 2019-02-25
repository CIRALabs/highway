# -*- ruby -*-

namespace :shg do

  desc "Create the contents for a QR code for a given PRODUCTID="
  task :dpp_pledge => :environment do
    productid = ENV['PRODUCTID']

    device = Device.find_by_number(productid)
    if device
      STDERR.puts "Found product #{device.id}"
      puts device.dppstring
    else
      STDERR.puts "No product found with ID=#{productid}"
    end
  end

end
