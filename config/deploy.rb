# config valid only for current version of Capistrano
lock "3.9.1"

set :application, "highway"
#set :repo_url, "git+ssh://code.credil.org/git/pandora/highway"
set :repo_url, "git@github.com:AnimaGUS-minerva/highway.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/data/highway/highway"

set :rvm_type, :system
set :rvm_ruby_version, '2.4.1'
set :rvm_roles,    [:app]
set :bundle_roles, [:app]


# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/database.yml", "config/secrets.yml", "config/environments/production.rb"

# Default value for linked_dirs is []
append :linked_dirs, "db/cert", "db/devices", "db/inventory", "log", "tmp"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

require 'byebug'

# override git:wrapper
#Rake::Task["git:wrapper"].clear_actions
namespace :git do
  desc "Upload the git wrapper script, this script guarantees that we can script git without getting an interactive prompt"
  task :wrapper2 do
    on release_roles :all do
      puts "Sending to: #{git_wrapper_path(@host)}"
      execute :mkdir, "-p", File.dirname(git_wrapper_path(@host)).shellescape
      script = StringIO.new("#!/bin/sh -e\nexec /usr/bin/ssh -l #{ENV['USER']} -o PasswordAuthentication=no -o StrictHostKeyChecking=no \"$@\"\n")
      upload! script, git_wrapper_path(@host)
      execute :chmod, "700", git_wrapper_path(@host).shellescape

      path = git_wrapper_path(nil)
      unless test("[ -f #{path.shellescape} ]")
        upload! script, path
      end
      execute :chmod, "700", git_wrapper_path(@host).shellescape
    end
  end
end

namespace :deploy do
  after :finished, :set_current_version do
    on roles(:app) do
      # dump current git version
      within release_path do
        execute :echo, "$REVISION = \"#{fetch(:revision_log_message)}\" >> config/initializers/revision.rb"
      end
    end
  end
end


module Capistrano
  module DSL
    module Paths
      def deploy_to(role = nil)
        dir = fetch(:deploy_to)

        host = role || @host
        if !host and Thread.current["sshkit_backend"]
          host = Thread.current["sshkit_backend"].host
        end
        #byebug unless host
        if host and host.properties and host.properties.fetch(:deploy_to)
          dir = host.properties.fetch(:deploy_to)
        end
        #puts "For #{host.hostname} deploy_to: #{dir}"
        dir
      end

      def git_wrapper_path(role = nil)
        if role
          tmppath = File.join(role.properties.fetch(:deploy_to), "tmp")
          hostname = role.hostname
        else
          tmppath = fetch(:tmp_dir)
          hostname = "generic"
        end
        suffix = %i(application stage local_user).map { |key| fetch(key).to_s }.join("-")
        path = "#{tmppath}/git-ssh-#{suffix}.sh"

        #puts "For #{hostname} wrapper_path: #{path}"
        path
      end


    end
  end
end
