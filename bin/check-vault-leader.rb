#! /usr/bin/env ruby
#
#   check-vault-leader.rb
#
# DESCRIPTION:
# => Check if valt has a leader
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: kube-client
#
# USAGE:
# -s SERVER - The kube server to use
# -l SERVICES - The comma delimited list of services to check
#
# NOTES:
#
# LICENSE:
#   Barry Martin <nyxcharon@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'json'
require 'vault'
require 'resolv'

class CheckVaultLeader< Sensu::Plugin::Check::CLI
    option :vault_token,
      description: 'Vault auth token',
      short: '-t TOKEN',
      long: '--TOKEN',
      default: ENV['VAULT_TOKEN']

    option :vault_address,
      description: 'Vault address',
      short: '-a ADDRESS',
      long: '--address',
      required: true

    option :verify_all,
      description: 'Verify all vault host',
      short: '-v True',
      long: '--verify',
      default: false


    def run
      addresses = Array.new
      if config[:verify_all] == 'true'
        Resolv.each_address(config[:vault_address]) do |addr|
          addresses.push(addr)
        end
      else
        addresses = Array(config[:vault_address])
      end

      failed = Array.new
      addresses.each do |addr|
        if hasleader(addr)
          failed.push(addr)
        end
      end

      if failed.empty?
        ok 'Vault has a leader'
      else
        critical "Problems found with vault server(s) #{failed}"
      end
    end

    def hasleader(ip)
      #Vault setup
      Vault::Client.new(address: config[ip], token: config[:vault_token])
      #Check seal status, return true if sealed
      begin
        status = Vault.sys.leader.leader_address
        if not status.nil?
          return false
        else
          return true
        end
      rescue => error
        return true
      end
    end
end
