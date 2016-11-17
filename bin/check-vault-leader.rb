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
      short: '-v',
      long: '--verify',
      boolean: true,
      default: false

    option :vault_port,
      description: 'The port vault uses',
      short: '-p PORT',
      long: '--port',
      default: '8200'

    option :ca_path,
      description: 'Path to ca certificate',
      short: '-c PATH',
      long: '--ca PATH'

    option :ssl,
      description: 'Should client use ssl to connect',
      short: '-s',
      long: '--ssl',
      boolean: true,
      default: false

    option :ssl_verify,
      description: 'Should client verify the ssl certificate',
      short: '-l',
      long: '--ssl-verify',
      boolean: true,
      default: false

    def run
      addresses = Array.new
      if config[:verify_all]
        Resolv.each_address(config[:vault_address]) do |addr|
          addresses.push(addr)
        end
      else
        addresses = Array(config[:vault_address])
      end
      failed = Array.new
      addresses.each do |addr|
        if not hasleader(addr)
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
      if config[:ssl] == false
        client = Vault::Client.new(address: "http://#{ip}:#{config[:vault_port]}", token: config[:vault_token])
      else
        client = Vault::Client.new(address: "https://#{ip}:#{config[:vault_port]}", token: config[:vault_token], ssl_ca_cert: config[:ca_path])
      end
      if config[:ssl_verify]
        client.ssl_verify = false
      end
     #Check for leader, return true if it has one
      begin
        status = client.sys.leader.address
        if not status.nil?
          return true
        else
          return false
        end
      rescue
        return false
      end
    end
end
