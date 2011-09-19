## Knife plugin to enable nginx maintenance mode
# From Harvest. www.getharvest.com
#
# Source: https://github.com/harvesthq/knife-plugins
#
# See http://wiki.opscode.com/display/chef/Knife+Plugins
# And: http://warwickp.com/2011/09/knife-plugin-for-nginx-maintenance-mode
#
## Install
# Place in .chef/plugins/knife/maintenance.rb
## Configure
# Set the role name that identifies your target servers in query below
#
## Usage
# $ knife maintenance --enable
# $ knife maintenance --disable

require 'chef/knife'
 
module Turnoffthedark
  class Maintenance < Chef::Knife
 
    deps do
      require 'chef/search/query'
      require 'chef/knife/ssh'
      Chef::Knife::Ssh.load_deps
    end
    
    option :enable,
    :short => '-e',
    :long => '--enable',
    :boolean => true,
    :description => "Turn maintenance mode on! PANIC"

    option :disable,
    :short => '-d',
    :long => '--disable',
    :boolean => true,
    :description => "Turn maintenance mode off"

    option :docroot,
    :long => '--docroot PATH',
    :description => 'Document Root path',
    :default => '/var/www'

    banner "knife maintenance --enable or --disable"

    def run

      if config[:enable]
        puts "WARNING: You are now turning off the world. PANIC."
        ssh_command = "sudo ln -s #{config[:docroot]}/maintenance.html #{config[:docroot]}/maintenanceON"
      elsif config[:disable]
        puts "OK: Turning us back on"
        ssh_command = "sudo rm #{config[:docroot]}/maintenanceON"
      else
        puts "I don't know what you want to do."
        exit
      end

      query = "role:nginx_production_lb"
      knife_ssh = Chef::Knife::Ssh.new()
      knife_ssh.name_args = [query, ssh_command]
      knife_ssh.run

    end
  end
end