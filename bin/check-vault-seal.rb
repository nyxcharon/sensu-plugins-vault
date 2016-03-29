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

    option :use_hostname,
      description: 'Use hostname instead of IP for vault servers.
                    Use this option to verify Vault server SSL certificates
                    (if --ssl is set to true) if they are issued with hostname.
                    Default is false',
      long: '--use-hostname'

    option :verify_all,
      description: 'Verify all vault host',
      short: '-v True',
      long: '--verify',
      default: false

    option :vault_port,
      description: 'The port vault uses',
      short: '-p PORT',
      long: '--port',
      default: '8200'

    option :ca,
      description: 'Path to a PEM encoded CA cert file to use to
                    verify the Vault server SSL certificate.',
      long: '--ca CA',
      default: nil

    option :insecure,
      description: 'change SSL verify mode to false. Not recommended',
      long: '--insecure'

    option :ssl,
      description: 'use HTTPS (default false)',
      long: '--ssl'

    def run

      addresses = Array.new
      if config[:use_hostname]
        if config[:verify_all] == 'true'
          config[:vault_address].each do |addr|
            addresses.push(addr)
          end
        else
          addresses = Array(config[:vault_address])
        end
      else
        if config[:verify_all] == 'true'
          Resolv.each_address(config[:vault_address]) do |addr|
            addresses.push(addr)
          end
        else
          addresses = Array(config[:vault_address])
        end
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

    def issealed(address)
      #Vault setup
      if config[:ssl]
        client = Vault::Client.new(
          address: "https://#{address}:#{config[:vault_port]}",
          token: config[:vault_token],
          ssl_ca_cert: config[:ca],
          ssl_verify: (config[:insecure] ? false : true)
        )
      else
        client = Vault::Client.new(address: "http://#{address}:#{config[:vault_port]}", token: config[:vault_token])
      end

      #Check seal status, return true if sealed
      begin
        status = client.sys.seal_status.sealed
        if status == false
          return false
        else
          return true
        end
      rescue => error
         return true
      end
    end
end
