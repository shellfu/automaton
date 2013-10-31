require_relative '../config/config'
require_relative 'backends/mongo_backend'
require_relative 'backends/yaml_backend'

module Automaton

  class MissingEntryError < ArgumentError; end

  class Helper
    def initialize
      @config = Automaton::Configure::config
      @dbtype = @config[:database_type]
      case @dbtype
        when 'mongo'
          @db = Automaton::Mongo_Backend::new
        when 'yaml'
          @db = Automaton::Yaml_Backend::new
        when 'json'
        # JSON NOT YET IMPLEMENTED @db = Automaton::JSONHelper::new
        else
          # ADD Graceful exit and proper logging.
      end
    end

    def find(name)
      @db.find(name)
    end

    def find_facts(name)
      @db.find_facts(name)
    end

    def add(name, data, type)
      @db.add(name, data, type)
    end

    def update(name, data, type)
      @db.update(name, data, type)
    end

    def save(name, data, type)
      @db.save(name, data, type)
    end

    def remove(name, type)
      @db.remove(name, type)
    end

  end
end