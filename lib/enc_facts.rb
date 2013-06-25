require 'net/https'
require 'uri'
require 'json'
require 'timeout'
require_relative 'log'

module Automaton
  class NodeFacts
    def self.retrieve_facts(name)
      config              = Automaton::Configure::config
      if config[:enablefacts] == 'true'
        # Break down curl -k -H 'Accept: pson' 'https://puppet:8140/production/facts/node'
        uri               = URI.parse("#{ config[:inventoryurl] }:#{ config[:inventoryport] }")
        path              = "/#{ config[:environment] }/facts/#{ name }"
        http              = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl      = true
        http.verify_mode  = OpenSSL::SSL::VERIFY_NONE
        request           = Net::HTTP::Get.new(path)
        request['Accept'] = 'pson'
        begin
          timeout(5) do
            Automaton::Log::msg('info', "INFO: Connecting to inventory service >#{ config[:inventoryurl] }:#{ config[:inventoryport] }<") if config[:verbose] == 'true'
            JSON.parse(http.request(request).body)['values'] if http.request(request)
          end
        rescue JSON::ParserError
          Automaton::Log::msg('warn', "WARNING: Could not find facts for #{ name }") if config[:verbose] == 'true'
          Hash.new(nil)
        rescue Errno::ECONNREFUSED, Timeout::Error
          Automaton::Log::msg('error', "ERROR: Cannot connect to inventory service >#{ config[:inventoryurl] }:#{ config[:inventoryport] }<") if config[:debug] == 'true'
          Hash.new(nil)
        end
      else
        Automaton::Log::msg('error', 'ERROR: >enablefacts< is Turned OFF in config.yml or simply not defined') if config[:debug] == 'true'
      end
    end
  end
end

