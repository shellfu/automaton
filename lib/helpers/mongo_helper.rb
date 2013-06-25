require_relative '../../config/config'
require 'mongo'
require 'yaml'

module Automaton

  class MongoHelper
    include Mongo
    def initialize
      @config   = Automaton::Configure::config

      # Connect to Mongo
      @hosts    = @config[:mdb_hosts].split(',')
      @client   = @config[:replicaset] == 'yes' ? MongoReplicaSetClient.new(@hosts) : MongoClient.new(@hosts[0])
      @database = @client[@config[:database]]

      # Set collection names
      @node_collection = @database[@config[:nodecollection]]
      @fact_collection = @database[@config[:factcollection]]

      # Set and Ensure Indexes on node name
      @node_collection.create_index('node', :unique => true)
      @node_collection.ensure_index('node', :unique => true)
      @fact_collection.create_index('node', :unique => true)
      @fact_collection.ensure_index('node', :unique => true)
    end

    def find(name)
      @node_collection.find_one(:node => name)
    end

    def find_facts(name)
      @fact_collection.find_one(:node => name)
    end

    def add(name, data, type)
      case type
        when 'node'
          @node_collection.insert(data)
        when 'fact'
          @fact_collection.insert(data)
        else
          # Gracefully Exit Add, and Log
      end
    end

    def update(name, data, type)
      case type
        when 'node'
          node_data = {'$set' => data}
          @node_collection.update(name, node_data)
          #@node_collection.update(name, data)
        when 'fact'
          fact_data = {'$set' => data}
          @fact_collection.update(name, fact_data)
        else
          # Gracefully Exit Add, and Log
      end
    end

    def save(name, data, type)
      case type
        when 'node'
          node_data = {'$set' => data}
          @node_collection.save(name, node_data)
        when 'fact'
          fact_data = {'$set' => data}
          @fact_collection.save(name, fact_data)
        else
          # Gracefully Exit Add, and Log
      end
    end

    def remove(name, type)
      case type
        when 'node'
          @node_collection.remove(name)
        when 'fact'
          @fact_collection.remove(name)
        else
          # Gracefully Exit Add, and Log
      end
    end

  end

end