require_relative '../config/config'
require_relative 'helper'
require_relative 'fact_helper'
require_relative 'recursive_merge'
require_relative 'node_helper'
require_relative 'log'
require 'yaml'
require 'json'

module Automaton

  class Node
    def initialize(options)
      @config    = Automaton::Configure::config
      @automaton = Automaton::Helper::new
      @log       = Automaton::Log
      @helper    = Automaton::NodeHelper::new
      @name      = options[:node]
      @result    = @automaton.find(@name)
      @env       = @helper.set_environment(options[:enc][:environment], @result ? @result['enc']['environment'] : nil)
      @classes   = @helper.set_classes(options[:enc][:classes], @result ? @result['enc']['classes'] : nil)
      @params    = @helper.set_parameters(options[:enc][:parameters], @result ? @result['enc']['parameters'] : nil)
      @inherits  = @helper.set_inherits(options[:inherit], @result ? @result['inherit'] : nil)
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


    def facts
      msg('info' , "Proceeding with Fact Retrieval and Storage for >#{ @name }<") if @config[:enablefacts] == 'true'
      store_facts(@name) if @config[:enablefacts] == 'true'
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
      final_hash['enc'] = {} if final_hash['enc'].nil?
      result = find(name)
      if result and result.has_key?('inherit') and not result['inherit'].to_s.empty?
        begin
          child = find_inheritance(result['inherit'])
          child.deep_merge(result['enc'])
          final_hash['enc'].deep_merge(child)
	      rescue
	        msg('to_file', "node: '#{ @inherits }' not_found for child node '#{ @name }' (Action: add node: #{ @inherits } to the ENC)")
          return @result['enc'] 
        end
      else 
        return final_hash['enc'].deep_merge(result['enc'])
      end
    end


    def lookup
      if @result
        node                = @result
        inheritance         = find_inheritance(@name)
        environment         = @result['enc']['environment']
        node['environment'] = environment unless environment.to_s.empty?
        if inheritance
          node['enc'] = inheritance
        else
          node['enc'] = @result['enc']
        end
        return JSON.parse(node['enc'].to_json)
      else 
	      return msg('info', "Node >#{ @name }< NOT found in the ENC")
      end
    end


    def add
      return 'entry_exists', '302', msg('info' , "Node Already Exists") if @result
      return 'successful', msg('info' , "Node >#{ @name }< added to the ENC.") if @automaton.add(@name, data, 'node')
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
        node_data = @helper.removal(@removal, @result)
        msg('info', "Removed item from >#{ @name }< in the ENC") if @automaton.update(@result, node_data, 'node')
      else
        msg('info', "Node >#{ @name }< Removed from ENC") if @automaton.remove(@result, 'node')
        msg('info', "Facts for node >#{ @name }< Removed from ENC") if @automaton.remove(facts_result, 'fact') if fact_result
      end
    end


    protected
    def store_facts(name)
      @config[:enablefacts] = 'false' if @config[:database_type] =~ /(yaml|json)/
      begin
        facts = Automaton::NodeFacts::retrieve_facts(name).to_hash
        node = (facts == {}) ? nil : {'node' => name, 'facts' => facts}
        update_facts = @automaton.update(name, node, 'fact') if node
        msg('info' , "Facts for node >#{ @name }< added to the ENC") if update_facts
      rescue
        msg('error', "Facts for >#{ @name }< could not be stored") if @config[:enablefacts] == 'true'
      end
    end

  end

end
