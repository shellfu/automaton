require_relative '../config/config'
require_relative 'helper'
require_relative 'fact_helper'
require_relative 'recursive_merge'
require_relative 'log'
require 'yaml'
require 'json'

module Automaton
  class Fact
    def initialize(data)
      @data        = data
      @config      = Automaton::Configure::config
      @automaton   = Automaton::Helper::new
      @fact_helper = Automaton::NodeFacts::new
      @name        = data[:node]
    end

    def msg(severity, msg)
      Automaton::Log.msg(severity, msg)
    end

    def fact
      case @data[:sub_command]
        when 'lookup'
          facts = find_facts(@name)
          if @data[:fact_name] == 'ALL'
            print facts['facts'].to_yaml
          else
            print "#{facts['facts'][@data[:fact_name]]}\n"
          end
        when 'collect'
          store_facts(@name)
        else
          return false
      end
    end

    def find_facts(name)
      @automaton.find(name, 'fact')
    end

    protected
    def store_facts(name)
      if @config[:enablefacts] == 'true'
        facts = @fact_helper.retrieve_facts(@name).to_hash
      else
        facts = {}
      end
      begin
        node = (facts == {}) ? nil : {'node' => name, 'facts' => facts}
        update_facts = @automaton.update(name, node, 'fact') if node
        msg('info' , "Facts for node >#{ name }< added to the ENC") if update_facts
      rescue
        msg('error', "Facts for >#{ name }< could not be stored") if @config[:enablefacts] == 'true'
      end
    end

  end
end
