# -*- ruby -*-

namespace :highway do

  desc "Do initial setup of sytem variables"
  task :setup_masa => :environment do

    SystemVariable.dump_vars

    print "Set initial serial number: (default 1)"
    serialnumber = STDIN.gets
    if serialnumber.blank?
      serialnumber = 1
    end
    SystemVariable.setnumber(:serialnumber, serialnumber)

    print "Hostname for this instance: "
    hostname = STDIN.gets
    SystemVariable.setvalue(:hostname, hostname)

    print "Inventory directory for this instance: "
    inv_dir = STDIN.gets
    SystemVariable.setvalue(:inventory_dir, inv_dir)

    print "Setup inventory base address"
    base_mac = STDIN.gets
    SystemVariable.setvalue(:base_mac, base_mac)

    SystemVariable.dump_vars
  end

end
