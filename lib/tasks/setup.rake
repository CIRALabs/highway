# -*- ruby -*-

namespace :highway do

  def prompt_variable(prompt, variable, previous)
    print prompt
    print "(default #{previous}): "
    value = STDIN.gets.chomp

    if value.blank?
      value = previous
    end

    value
  end

  def prompt_variable_number(prompt, variable)
    SystemVariable.setnumber(variable,
                             prompt_variable(prompt,
                                             variable,
                                             SystemVariable.number(variable)))
  end

  def prompt_variable_value(prompt, variable)
    SystemVariable.setvalue(variable,
                            prompt_variable(prompt,
                                            variable,
                                            SystemVariable.string(variable)))
  end

  def set_iauthority
    SystemVariable.setvalue(:masa_iauthority, sprintf("%s:%u",
                                                      SystemVariable.string(:hostname),
                                                      SystemVariable.number(:portnum)))
  end

  desc "Do initial setup of system variables, non-interactively, HOSTNAME=foo"
  task :h0_set_hostname => :environment do
    SystemVariable.setvalue(:hostname, ENV['HOSTNAME'])
    SystemVariable.setnumber(:portnum, ENV['PORT'])
    set_iauthority
    puts "MASA URL is #{SystemVariable.string(:masa_iauthority)}"
  end

  desc "Do initial setup of sytem variables"
  task :h0_setup_masa => :environment do

    SystemVariable.dump_vars

    prompt_variable_value("Hostname for this instance",
                          :hostname)

    prompt_variable_number("Port number this instance",
                          :portnum)

    prompt_variable_value("DN prefix for certificates",
                          :dnprefix)

    prompt_variable_value("Inventory directory for this instance",
                          :inventory_dir)

    prompt_variable_value("Setup inventory base mac address",
                          :base_mac)

    set_iauthority
    SystemVariable.dump_vars
  end

end
