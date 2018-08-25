# -*- ruby -*-

namespace :highway do

  desc "Sign a MUD json file"
  task :mud_json_sign => :environment do
    file = ENV['FILE']
    muddata = File.read(file)
  end

end
