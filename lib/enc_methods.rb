require_relative '../config/config'
require_relative 'helpers/helper'
require_relative 'helpers/fact_helper'
require_relative 'helpers/hash_helper'
require_relative 'helpers/merge_helper'
require_relative 'log'
require 'yaml'

module Automaton

  class ENCMethods
    def initialize
      @config      = Automaton::Configure::config
      @automaton   = Automaton::Helper::new
      @log         = Automaton::Log
      @hash_helper = Automaton::HashHelper
    end

    def str2hash(string, delimiter, type)
      @hash_helper.str2hash(string, delimiter, type)
    end

    def msg(severity, msg)
      @log.msg(severity, msg)
    end

    def store_facts(name)
      @config[:enablefacts] = 'false' if @config[:database_type] == 'yaml'
      begin
        facts = Automaton::NodeFacts::retrieve_facts(name).to_hash
        node = if facts == {}
                 nil
               else
                 { 'node' => name, 'facts' => facts }
               end
        @automaton.add(name, node, 'fact') if node
        msg('info' , "INFO: Facts for node >#{ name }< has been added to the ENC") if @automaton.add(name, node, 'fact')
      rescue
        msg('error', "ERROR: Facts for >#{ name }< could not be stored") if @config[:enablefacts] == 'true'
      end
    end

    def find(name)
      @automaton.find(name)
    end

    def find_facts(name)
      @automaton.find_facts(name)
    end

    def find_inheritance(name)
      final_hash = {}
      result = find(name)
      final_hash['enc'] = {} if final_hash['enc'].nil?
      if result.has_key?('inherit') and not result['inherit'].to_s.empty?
        child = find_inheritance(result['inherit'])
        child.deep_merge(result['enc'])
        final_hash['enc'].deep_merge(child)
      else
        final_hash['enc'].deep_merge(result['enc'])
      end
    end

    def lookup(name)
      result = find(name)
      if result
        node                = result
        node['enc']         = find_inheritance(name)
        environment         = result['enc']['environment']
        node['environment'] = environment unless environment.to_s.empty?

        # In the event inherited node isn't found
        # Log that it wasn't found, and set to result['enc']
        #if node['enc'] == nil and it has key inherit
        #  node['enc'] = result['enc']
        #end

        node = Automaton::NodeFacts::deep_iterate(node)
        return node['enc'].convert_bson_hash
      else
        msg('warn', "WARNING: Node >#{ name }< NOT found in the ENC")
        return 'not_found'
      end
    end

    def add(name, environment = nil, classes = nil, parameters = nil, inherits = nil)
      result = find(name)
      if result
        msg('warn', "WARNING: Node >#{ name }< already exists in the ENC")
        return 'existing_entry'
      end

      classes     = str2hash(classes, '^', 'class') if classes
      parameters  = str2hash(parameters, '=', 'parameter') if parameters
      inherits    = inherits.to_s unless inherits.to_s.empty?
      environment = environment.to_s.empty? ? @config[:environment] : environment

      node_data = { 'node' => name, 'enc' => { 'environment' => environment, 'classes' => classes, 'parameters' => parameters }, 'inherit' => inherits }
      msg('info' , "INFO: Node >#{ name }< has been added to the ENC.") if @automaton.add(name, node_data, 'node')
      msg('info' , "Proceeding with Fact Retrieval and Storage for >#{ name }<") if @config[:enablefacts] == 'true'
      store_facts(name)
    end

    def update(name, environment = nil, classes = nil, parameters = nil, inherits = nil)
      # Find the Node that needs Updating
      result = find(name)

      # Reference to the Environment, ENC Classes hash & ENC Parameters hash
      environment ? env = environment : env = result['enc']['environment']
      classes_hash      = result['enc']['classes']
      parameters_hash   = result['enc']['parameters']

      # Classes
      classes = if classes
                  if classes_hash.to_s.empty?
                    str2hash(classes, '^', 'class')
                  else
                    classes_hash.deep_merge(str2hash(classes, '^', 'class'))
                  end
                else
                  classes_hash
                end

      # Parameters
      params = if parameters
                 if parameters_hash.to_s.empty?
                   str2hash(parameters, '=', 'parameter')
                 else
                   parameters_hash.deep_merge(str2hash(parameters, '=', 'parameter'))
                 end
               else
                 parameters_hash
               end

      # Inherit
      inherits = if inherits
                   inherits.to_s
                 elsif result['inherit']
                   result['inherit']
                 end

      # Environment
      environment = (environment.to_s.empty? and env.to_s.empty?) ? @config[:environment] : env.to_s

      node_data = {'node' => name, 'enc' => {'environment' => environment, 'classes' => classes, 'parameters' => params}, 'inherit' => inherits}
      msg('info', "INFO: Node >#{ name }< Updated") if @automaton.update(result, node_data, 'node')
    end

    def remove(name, classes = nil, parameters = nil)
      result = find(name)
      facts_result = find_facts(name) if @config[:enablefacts] == 'true' and @config[:database_type] == 'mongo'

      unless result
        msg('info', "INFO: Node >#{ name }< NOT found in the ENC")
        return 'not_found'
      end

      if classes or parameters
        classes = if classes
                    str2hash(classes, '^', 'class').each_pair do |k, v|
                      if result['enc']['classes'].key?(k)

                        if v.is_a? Hash then
                          (v.each_pair do |key, value|

                            result['enc']['classes'][k].delete(key)
                            if result['enc']['classes'][k].length == 0
                              result['enc']['classes'][k] = nil
                            end
                          end)
                        else
                          result['enc']['classes'].delete(k)
                        end
                      else
                        result['enc']['classes']
                      end
                    end
                  else
                    result['enc']['classes']
                  end


        parameters = if parameters and result['enc']['parameters'].include? parameters
                       result['enc']['parameters'].delete_if { |key, value| key == parameters }
                       if result['enc']['parameters'].length == 0
                         result['enc']['parameters'] = nil
                       end
                     else
                       result['enc']['parameters']
                     end

        node = { 'enc' => { 'classes' => result['enc']['classes'], 'parameters' => result['enc']['parameters'] } } if @config[:database_type] == 'yaml'
        node = { 'enc' => { 'classes' => classes, 'parameters' => parameters } } if @config[:database_type] == 'mongo'
        msg('info', "INFO: Removed item from >#{ name }< in the ENC") if @automaton.save(result, node, 'node')
      else
        msg('info', "INFO: Node >#{ name }< Removed from ENC") if @automaton.remove(result, 'node')
        msg('info', "INFO: Facts for node >#{ name }< Removed from ENC") if @automaton.remove(facts_result, 'fact') if facts_result
      end
    end
  end

end