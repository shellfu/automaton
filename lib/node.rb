require_relative '../config/config'
require_relative 'helper'
require_relative 'fact_helper'
require_relative 'recursive_merge'
require_relative 'log'
require 'yaml'
require 'json'

module Automaton

  class Node
    def initialize(options)
      @config    = Automaton::Configure::config
      @automaton = Automaton::Helper::new
      @log       = Automaton::Log
      @name      = options[:node]
      @result    = @automaton.find(@name)
      @env       = set_environment(options[:enc][:environment], @result ? @result['enc']['environment'] : nil)
      @classes   = set_classes(options[:enc][:classes], @result ? @result['enc']['classes'] : nil)
      @params    = set_parameters(options[:enc][:parameters], @result ? @result['enc']['parameters'] : nil)
      @inherits  = set_inherits(options[:inherit], @result ? @result['inherit'] : nil)
      @removal   = options
    end

    def data
      { 'node' => @name,
        'enc' => {
            'environment' => @env,
            'classes'     => @classes,
            'parameters'  => @params
        },
        'inherit' => @inherits
      }
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

    def lookup
      if @result
        node                = @result
        node['enc']         = find_inheritance(@name)
        environment         = @result['enc']['environment']
        node['environment'] = environment unless environment.to_s.empty?

        # In the event inherited node isn't found
        # Log that it wasn't found, and set to result['enc']
        #if node['enc'] == nil and it has key inherit
        #  node['enc'] = result['enc']
        #end

        node = Automaton::NodeFacts::deep_iterate(node)
        return JSON.parse(node['enc'].to_json)
      else
        return msg('info', "Node >#{ @name }< NOT found in the ENC")
      end
    end

    def add
      return 'entry_exists', '302', msg('info' , "Node Already Exists") if @result
      return 'successful', msg('info' , "Node >#{ @name }< added to the ENC.") if @automaton.add(@name, data, 'node')
      #msg('info' , "Proceeding with Fact Retrieval and Storage for >#{ @name }<") if @config[:enablefacts] == 'true'
      #store_facts(@name) if @config[:enablefacts] == 'true'
    end

    def update
      return 'successful', msg('info', "Node >#{ @name }< Updated") if @automaton.update(@result, data, 'node')
    end

    def remove
      unless @result
        msg('info', "Node >#{ @name }< NOT found in the ENC")
        return 'not_found'
      end
      fact_result = find_facts(@name) if @config[:database_type] == 'mongo'
      remove_node = (@removal[:enc][:classes] or @removal[:enc][:parameters])
      if remove_node
        node_data = removal(@removal, @result)
        msg('info', "Removed item from >#{ @name }< in the ENC") if @automaton.update(@result, node_data, 'node')
      else
        msg('info', "Node >#{ @name }< Removed from ENC") if @automaton.remove(@result, 'node')
        msg('info', "Facts for node >#{ @name }< Removed from ENC") if @automaton.remove(facts_result, 'fact') if fact_result
      end
    end

    protected
    def store_facts(name)
      @config[:enablefacts] = 'false' if @config[:database_type] == 'yaml'
      begin
        facts = Automaton::NodeFacts::retrieve_facts(name).to_hash
        node = (facts == {}) ? nil : {'node' => name, 'facts' => facts}
        @automaton.add(name, node, 'fact') if node
        msg('info' , "Facts for node >#{ @name }< added to the ENC") if @automaton.add(@name, node, 'fact')
      rescue
        msg('error', "Facts for >#{ @name }< could not be stored") if @config[:enablefacts] == 'true'
      end
    end

    def removal(new_hash, old_hash)
      if new_hash[:enc][:classes]
        class_name      = new_hash[:enc][:classes].split('^')
        class_parameter = class_name.pop
        class_name.inject(old_hash['enc']['classes']) { |h, el| h[el] }.delete class_parameter
      end
      old_hash['enc']['parameters'].delete( new_hash[:enc][:parameters].to_s ) if new_hash[:enc][:parameters]
      old_hash
    end

    def set_environment(new_environment, old_environment)
      return @config[:environment] if new_environment.to_s.empty? and old_environment.to_s.empty?
      return old_environment if new_environment.to_s.empty?
      new_environment
    end

    def set_parameters(new_hash, original_hash)
      new_hash = Hash[new_hash.split(',').map { |str| str.split('=') }.inject({}) { |c, (key, v)| c[key] = v; c }] unless new_hash.nil?
      return nil if original_hash.to_s.empty? and new_hash.to_s.empty?
      return new_hash if original_hash.to_s.empty?
      return original_hash if new_hash.to_s.empty?
      return original_hash.deep_merge(new_hash) if original_hash
      new_hash
    end

    def set_classes(new_hash, original_hash)
      new_hash = Hash[new_hash.split(',').map{ |s| k, *v = s.split('^'); [k, v.empty? ? nil : Hash[v.map{|x|x.split('=')}]]}] unless new_hash.nil?
      return nil if original_hash.to_s.empty? and new_hash.to_s.empty?
      return new_hash if original_hash.to_s.empty?
      return original_hash if new_hash.to_s.empty?
      return original_hash.deep_merge(new_hash) if original_hash
      new_hash
    end

    def set_inherits(new_inherits, old_inherits)
      return nil if new_inherits.to_s.empty? and old_inherits.to_s.empty?
      return old_inherits if new_inherits.to_s.empty?
      new_inherits
    end

  end

end