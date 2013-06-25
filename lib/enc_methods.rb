require_relative '../config/config'
require_relative 'log'
require_relative 'enc_facts'
require_relative 'hash_helper'
require_relative 'helpers/helper'
require_relative 'recursive_merge'
require 'yaml'

module Automaton

  class BSON::OrderedHash
    def to_h
      inject({}) { |key, value| k, v = value; key[k] = ( if v.class == BSON::OrderedHash then v.to_h else v end); key }
    end

    def to_json
      to_h.to_json
    end

    def to_yaml
      to_h.to_yaml
    end
  end

  class ENCMethods < BSON::OrderedHash
    def initialize
      @config      = Automaton::Configure::config
      @automaton   = Automaton::Helper::new
      @log         = Automaton::Log
      @hash_helper = Automaton::HashHelper
    end

    def str2hash(string, delimiter, type)
      @hash_helper.str2hash(string, delimiter, type)
    end

    def pmerge
      @hash_helper.pmerge
    end

    def msg(severity, msg)
      @log.msg(severity, msg)
    end

    def find(name)
      @automaton.find(name)
    end

    def find_facts(name)
      @automaton.find_facts(name)
    end

    def find_inheritance(name)
      result = find(name)
      if result.has_key?('inherit') and not result['inherit'].to_s.empty?
        inode = find(result['inherit'])
        inode['enc']['classes'] ? (inode['enc']['classes'] unless inode['enc']['classes'].to_s.empty?) : nil if inode
      else
        nil
      end
    end

    def store_facts(name)
      @config[:enablefacts] = 'false' unless @config[:database_type] == 'mongo'
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

    def lookup(name)
      begin
        result = find(name)
        if result
          inheritance = find_inheritance(name)

          if result['inherit'].to_s.empty?
            result['enc']['classes']
          elsif result['enc']['classes'].to_s.empty?
            result['enc']['classes'] = inheritance
          else
            if inheritance
              result['enc']['classes'] = inheritance.rmerge(result['enc']['classes'])
            else
              result['enc']['classes']
            end
          end
          result['enc']
        else
          msg('warn', "WARNING: Node >#{ name }< NOT found in the ENC")
          return 'not_found'
        end
      rescue ArgumentError => e
        msg('error', ">#{e.msg}<")
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
      env    = result['enc']['environment']
      c_hash = result['enc']['classes']
      p_hash = result['enc']['parameters']

      # Classes
      classes = if classes
        if c_hash.to_s.empty?
          str2hash(classes, '^', 'class')
        else
          c_hash.inject({}) { |h, (k, v)| v.nil? ? h[k] = nil : h[k] = v; h }.merge(str2hash(classes, '^', 'class'), &pmerge)
        end
      else
        c_hash
      end

      # Parameters
      params = if parameters
        if p_hash.to_s.empty?
          str2hash(parameters, '=', 'parameter')
        else
          p_hash.rmerge(str2hash(parameters, '=', 'parameter'))
        end
      else
        p_hash
      end

      # Inherit
      inherits = if inherits
        inherits.to_s
      elsif result['inherit']
        result['inherit']
      end

      # Environment
      environment = if environment.to_s.empty? and env.to_s.empty?
        @config[:environment]
      else
        env.to_s
      end

      node_data = {'node' => name, 'enc' => {'environment' => environment, 'classes' => classes, 'parameters' => params}, 'inherit' => inherits}
      msg('info', "INFO: Node >#{ name }< Updated") if @automaton.update(result, node_data, 'node')
    end

    def remove(name, nclass = nil, parameters = nil)
      result = find(name)
      facts_result = find_facts(name) if @config[:enablefacts] == 'true'

      unless result
        msg('info', "INFO: Node >#{ name }< NOT found in the ENC")
        return 'not_found'
      end

      if nclass and parameters
        msg('warn', 'WARNING: Only 1 Class or 1 Parameter may be removed at a time')
      elsif nclass
        # Classes
        classes = if nclass and nclass.include? 'DELETE'
          nil
        elsif nclass and result['enc']['classes'].include? nclass
          result['enc']['classes'].delete_if { |key, value| key == nclass }
        else
          msg('info', "INFO: Class >#{ nclass }< NOT found in >#{ name }<")
        end

        node = { 'enc' => { 'classes' => classes } }
        msg('info', "INFO: Class >#{ nclass }< Removed from >#{ name }< in the ENC") if @automaton.save(result, node, 'node')

      elsif parameters
        # Parameters
        params = if parameters and parameters.include? 'DELETE'
          nil
        elsif parameters and result['enc']['parameters'].include? parameters
          result['enc']['parameters'].delete_if { |key, value| key == parameters }
        else
          msg('info', "INFO: Parameter >#{ parameters }< NOT found in >#{ name }<")
        end

        node = { 'enc' => { 'parameters' => params } }
        msg('info', "INFO: Parameter >#{ parameters }< Removed from >#{ name }< in the ENC") if @automaton.save(result, node, 'node')
      else
        msg('info', "INFO: Node >#{ name }< Removed from ENC") if @automaton.remove(result, 'node')
        msg('info', "INFO: Facts for node >#{ name }< Removed from ENC") if @automaton.remove(facts_result, 'fact') if facts_result
      end
    end

  end

end