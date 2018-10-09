# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

set :rvm_custom_path, '/usr/share/rvm'
set :rvm_type, :system
set :rvm_ruby_version, '2.5.1'

server "florean.sandelman.ca",
       user: "highway",
       roles: %w{app db web},
       deploy_to: '/home/highway',
       ssh_options: {
         user: ENV['USER']
       }

# Global options
# --------------
set :ssh_options, {
      forward_agent: true,
    }

