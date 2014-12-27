require 'net/https'
require 'uri'
require 'json'
require 'timeout'
require_relative 'log'

module Automaton
  class NodeFacts
    def initialize
      @fact_list = {}
      @config              = Automaton::Configure::config
    end

    def retrieve_facts(name)
      if @config[:enablefacts] == 'true'
        host              = @config[:inventoryurl].split(':')
        # Break down curl -k -H 'Accept: pson' 'https://puppet:8140/production/facts/node'
        uri               = URI.parse("https:#{ host[1] }:#{ host[2] }")
        path              = "/#{ @config[:environment] }/facts/#{ name }"
        http              = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl      = true
        http.verify_mode  = OpenSSL::SSL::VERIFY_NONE
        request           = Net::HTTP::Get.new(path)
        request['Accept'] = 'pson'
        begin
          timeout(5) do
            JSON.parse(http.request(request).body)['values'] if http.request(request)
          end
        rescue JSON::ParserError
          Automaton::Log::msg('warn', "WARNING: Could not find facts for #{ name }") if @config[:verbose] == 'true'
          Hash.new(nil)
        rescue Errno::ECONNREFUSED, Timeout::Error
          Automaton::Log::msg('error', "ERROR: Cannot connect to inventory service >#{ host }:#{ port }<") if @config[:debug] == 'true'
          Hash.new(nil)
        end
      else
        Automaton::Log::msg('error', 'ERROR: >enablefacts< is Turned OFF in config.yml or simply not defined') if @config[:debug] == 'true'
      end
    end

    def deep_iterate(hash)
      if @config[:enablefacts] == 'true'
        @fact_hash = retrieve_facts(hash['node']) if hash['node']
        hash.each_pair do |k,v|
          if v.is_a?(Hash)
            deep_iterate(v)
          else
            #puts "key: #{k} value: #{v}"
            if v =~ /(?<=\{)(.*?)(?=\})/
              @fact_name = v.match(/(?<=\{)(.*?)(?=\})/) {|m| m.to_s}.sub(%r{^::}, '')
              value      = v.gsub(/%\{.*\}/, (@fact_hash[@fact_name] ? @fact_hash[@fact_name] : 'undef_(chk inv service on pm)'))
              hash[k]    = value
            end
          end
        end
        return hash
      else
        return hash
      end

    end
  end
end

