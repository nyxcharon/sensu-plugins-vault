#! /usr/bin/env ruby
#
#   check-vault-seal.rb
#
# DESCRIPTION:
# => Check if vault is sealed
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

class CheckVaultSeal< Sensu::Plugin::Check::CLI
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
        if issealed(addr)
          failed.push(addr)
        end
      end

      if failed.empty?
        ok 'All vault servers ok'
      else
        critical "Problems found with vault server(s) #{failed}"
      end

    end

    def issealed(ip)
      #Vault setup
      Vault::Client.new(address: config[ip], token: config[:vault_token])
      #Check seal status, return true if sealed
      #begin
        status = Vault.sys.seal_status.sealed
        if status == false
          return false
        else
          return true
      #   end
      # rescue => error
      #   return true
      end
    end
end
