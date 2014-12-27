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
      @data        = options
      @config      = Automaton::Configure::config
      @automaton   = Automaton::Helper::new
      @helper      = Automaton::NodeHelper::new
      @name        = options[:node]
      @result      = @automaton.find(@name, 'node')
    end


    def data
      env       = @helper.set_environment(@data[:enc][:environment], @result ? @result['enc']['environment'] : nil)
      classes   = @helper.set_classes(@data[:enc][:classes], @result ? @result['enc']['classes'] : nil)
      params    = @helper.set_parameters(@data[:enc][:parameters], @result ? @result['enc']['parameters'] : nil)
      inherits  = @helper.set_inherits(@data[:inherit], @result ? @result['inherit'] : nil)
      data = { 'node' => @name,
                'enc' => {
                    'environment' => env,
                    'classes'     => classes,
                    'parameters'  => params
                },
                'inherit' => inherits
              }
      return data
    end

    def facts
      Automaton::NodeFacts::new
    end

    def msg(severity, msg)
      Automaton::Log.msg(severity, msg)
    end


    def find(name)
      @automaton.find(name, 'node')
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
        node = facts.deep_iterate(node)
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
      print data
      return 'successful', msg('info', "Node >#{ @name }< Updated") if @automaton.update(@result, data, 'node')
    end


    def remove
      puts @result
      unless @result
        msg('info', "Node >#{ @name }< NOT found in the ENC")
        return 'not_found'
      end
      remove_node = (@data[:enc][:classes] or @data[:enc][:parameters])
      if remove_node
        node_data = @helper.removal(@data, @result)
        msg('info', "Removed item from >#{ @name }< in the ENC") if @automaton.update(@result, node_data, 'node')
      else
        msg('info', "Node >#{ @name }< Removed from ENC") if @automaton.remove(@result, 'node')
      end
    end

  end

end
