## Knife plugin to generate an OpenSSH config file from a Chef search
# From Harvest. www.getharvest.com
#
# Source: https://github.com/harvesthq/knife-plugins
#
# See http://wiki.opscode.com/display/chef/Knife+Plugins
# See http://www.openbsd.org/cgi-bin/man.cgi?query=ssh_config&sektion=5
#
## Install
# Place in .chef/plugins/knife/sshgen.rb
#
## Usage
# $ knife sshgen -p to print a config stanza to the screen
# $ knife sshgen -w to append to your current ~/.ssh/config file
#
## Suggestion
# use with bash-completion, by installing bash-completion and adding this to ~/.bash_profile:
# complete -W "$(echo `cat ~/.ssh/config | grep Hostname | uniq | awk '{print $2}'`;)" ssh
#
## Credit
# Hints taken from: https://github.com/danielsdeleo/knife-plugins/blob/master/deploy.rb
# Hints taken from: https://github.com/javan/whenever

module MakeSSHConfigFile
  class Sshgen < Chef::Knife

    banner "knife sshgen -w OR -p"

    option :ssh_config_file,
    :long => "--config-file",
    :short => "-c",
    :description => "The name of your SSH config file",
    :default => "#{ENV['HOME']}/.ssh/config"

    option :print,
    :long => "--print",
    :short => "-p",
    :description => "Print the ssh config entry here in this screen",
    :default => true

    option :write,
    :long => "--write",
    :short => "-w",
    :description => "Write (append) the config to local SSH config file",
    :default => false

    deps do
      require 'chef/search/query'
      require 'chef/cookbook_version'
      require 'chef/knife/ssh'
    end

    def run      

      unless config[:print] || config[:write]
        ui.error "You must specify either --print or --write."
        exit
      end

      nodes = find_all_nodes
      ssh_config = build_ssh_config(nodes)

      if config[:write]

        unless File.exists? config[:ssh_config_file]
          ui.msg "WARNING: #{config[:ssh_config_file]} non-existent, but I'll try anyway"
        end
        
        new_ssh_config = read_ssh_config
        
        if new_ssh_config.index(comment_open) && new_ssh_config.index(comment_close) #we have an existing config in between our markers, update it
          final_ssh_config = new_ssh_config.gsub(Regexp.new("#{comment_open}.+#{comment_close}", Regexp::MULTILINE), "#{comment_open}\n#{ssh_config.chomp}\n#{comment_close}")
        else # no existing markers, we'll append them
          final_ssh_config = "#{new_ssh_config}\n#{comment_open}\n#{ssh_config}#{comment_close}"
        end
        
        write_ssh_config(final_ssh_config)
      elsif config[:print]
        ui.msg "#{ssh_config}"
      end
    end

    def find_all_nodes
      query = "name:*"
      searcher = Chef::Search::Query.new
      rows, _start, _total = searcher.search(:node, query)
      if rows.empty?
        ui.error "No nodes matched the query: #{query}"
        exit 1
      end

      rows
    end

    def build_ssh_config(my_nodes)
      ssh_config_block = ""
      my_nodes.each do |n|
        ssh_config_block << "Host #{n[:fqdn]} \n"
        ssh_config_block << "\t Hostname #{n[:fqdn]} \n"
      end

      ssh_config_block
    end

    def read_ssh_config
      file = File.open(config[:ssh_config_file], "r+")
      ssh_config_contents = ""
      while(!file.eof?)
        ssh_config_contents << file.readline
      end
      file.close()

      ssh_config_contents
    end

    def write_ssh_config(contents)
      begin
        File.open(config[:ssh_config_file], 'w') {|f| f.write(contents) }
      rescue
        ui.error "ERROR: Writing #{config[:ssh_config_file]} failed."
      else    
        ui.msg "Appended to: #{config[:ssh_config_file]}"
      end  
    end

    def comment_open
      "###STARTSSHGEN"
    end

    def comment_close
      "###ENDSSHGEN"
    end


  end
end