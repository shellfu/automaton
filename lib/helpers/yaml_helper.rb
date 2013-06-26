require_relative '../../config/config'
require_relative '../log'
require_relative 'node_helper'
require 'json'
require 'yaml'

module Automaton

  class MissingEntryError < ArgumentError; end

  class YamlHelper
    def initialize
      @config      = Automaton::Configure::config
      @node        = Automaton::NodeHelper
      Dir.mkdir(@config[:data_path]) unless Dir.exist?(@config[:data_path])
    end

    def msg(severity, msg)
      Automaton::Log.msg(severity, msg)
    end

    # Find an Entry
    def find(name)
      path = "#{@config[:data_path]}/#{ name }.yaml"
      if File.exists?(path)
        node = File.open(path, 'r')
        load(node)
      else
        nil
      end

    end

    # Create a new entry.
    def add(name, data, type)
      path = "#{@config[:data_path]}/#{ name }.yaml"
      h = data.to_hash.to_yaml
      File.open("#{@config[:data_path]}/#{ name }.yaml", 'w+') { |f| f.write(h) } unless File.exists?(path)
    end

    # Update the node object to the database.
    def update(name, data, type)
      path = "#{@config[:data_path]}/#{name['node']}.yaml"
      File.open(path, 'w') { |f| f.write(data.to_yaml) }
    end

    # save the node object to the database.
    def save(name, data, type)
      path = "#{@config[:data_path]}/#{name['node']}.yaml"
      original = load(path)
      if data['enc'].has_key?('classes') then
        original['enc']['classes'] = data['enc']['classes'] if type == 'node'
      elsif data['enc'].has_key?('parameters')
        original['enc']['parameters'] = data['enc']['parameters'] if type == 'node'
      else
        # CONTINUE AND LOG
      end
      File.open(path, 'w') { |f| f.write(original.to_yaml) }
    end

    # Delete a entry by name.
    def remove(name, type)
      path = "#{@config[:data_path]}/#{name['node']}.yaml"
      if File.exists?(path)
        puts "Deleting File: #{ path }"
        File.delete(path)
      else
        msg('info', "#{ path } not found")
      end
    end

    # Load YAML file and Convert to Hash
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
        yaml_data = YAML.load_file(path)
        data.merge!(yaml_data) if yaml_data
      rescue ArgumentError => e
        msg('error', "Could not load >#{name}<: >#{e.msg}<")
        raise "Could not load #{ @type } >#{ name }<: #{ e.msg }"
      end

      data
    end

  end
end
