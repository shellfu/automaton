require_relative '../../config/config'
require_relative '../log'
require 'json'
require 'yaml'

module Automaton

  class MissingEntryError < ArgumentError; end

  class FileBackend
    def initialize
      @config      = Automaton::Configure::config
      @filetype    = @config[:database_type]
      @to_filetype = (@filetype == 'json') ? to_json : to_yaml
      Dir.mkdir(@config[:data_path]) unless Dir.exist?(@config[:data_path])
      Dir.mkdir(@config[:fact_path]) unless Dir.exist?(@config[:fact_path])
      Dir.mkdir(@config[:group_path]) unless Dir.exist?(@config[:group_path])
    end

    def determine_path(name, type)
      case type
        when 'group'
          return "#{@config[:group_path]}/#{ name }.#{ @filetype }"
        when 'fact'
          return "#{@config[:fact_path]}/#{ name }.#{ @filetype }"
        else
          return "#{@config[:data_path]}/#{ name }.#{ @filetype }"
      end
    end

    def msg(severity, msg)
      Automaton::Log.msg(severity, msg)
    end

    # Find an Entry
    def find(name, type)
      path = determine_path(name,type)
      if File.exists?(path)
        node = File.open(path, 'r')
        load(node)
      else
        nil
      end
    end

    # Create a new entry.
    def add(name, data, type)
      path = determine_path(name,type)
      h = (@filetype == 'json') ? data.to_hash.to_json : data.to_hash.to_yaml
      File.open(path, 'w+') { |f| f.write(h) } unless File.exists?(path)
    end

    # Update the node object to the database.
    def update(name, data, type)
      h = (@filetype == 'json') ? data.to_json : data.to_yaml
      File.open(determine_path(name['node'],type), 'w') { |f| f.write(h) }
    end

    # Delete a entry by name.
    def remove(name, type)
      path = "#{@config[:data_path]}/#{name['node']}.#{ @filetype }"
      if File.exists?(path)
        msg('info', "Deleting File: #{ path }")
        File.delete(path)
      else
        msg('info', "#{ path } not found")
      end
    end

    # Load JSON file and Convert to Hash
    def load(path)
      # Default values for any missing keys
      data = Hash.new do |hash, key|
        case key
          when 'classes', 'parameters', 'facts'
            hash[key.to_s] = Hash.new
          when 'environment'
            hash[key.to_s] = @config[:environment]
          else
            hash[key.to_s] = nil
        end
      end

      begin
        data = (@filetype == 'json') ? JSON.load(path) : YAML.load_file(path)
        data.merge!(data) if data
      rescue ArgumentError => e
        msg('error', "Could not load >#{name}<: >#{e.msg}<")
        raise "Could not load #{ @type } >#{ name }<: #{ e.msg }"
      end

      data
    end

  end
end