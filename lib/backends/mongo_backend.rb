require_relative '../../config/config'
require 'mongo'
require 'yaml'

module Automaton

  class MongoBackend
    include Mongo
    def initialize
      config    = Automaton::Configure::config
      # Connect to Mongo
      hosts     = config[:mdb_hosts].split(',')
      host,port = hosts[0].split(':')
      client    = (config[:replicaset] == 'yes') ? MongoReplicaSetClient.new(hosts) : MongoClient.new(host, port)
      database  = client[config[:database]]

      # Authenticate, if set
      database.authenticate(config[:username], config[:password]) unless config[:username].to_s.empty?

      # Set collection names
      @node_collection = database[config[:nodecollection]]
      @fact_collection = database[config[:factcollection]]

      # Set and Ensure Indexes on node name
      [ @node_collection, @fact_collection ].each do |collection|
        collection.create_index('node', :unique => true)
        collection.ensure_index('node', :unique => true)
      end
    end

    def determine_collection(type)
      case type
        when 'node'
          @node_collection
        when 'fact'
          @fact_collection
        else
          msg('warn',"#{type} is not supported")
      end
    end

    def msg(severity, message)
      Automaton::Log::msg(severity, message)
    end

    def find(name, type)
      return determine_collection(type).find_one(:node => name)
    end

    def find_facts(name)
      @fact_collection.find_one(:node => name)
    end

    def add(name, data, type)
      return determine_collection(type).insert(data)
    end

    def update(name, data, type)
      return determine_collection(type).update({ :_id => name["_id"] }, data)
    end

    def remove(name, type)
      return determine_collection(type).remove(name)
    end

  end

end
