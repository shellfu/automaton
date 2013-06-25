require_relative 'yaml_helper'

module Automaton
  class NodeHelper

    def initialize(name, data={})
      @type        = :node
      @name        = name
      @environment = data['enc']['environment']
      @classes     = data['enc']['classes']
      @parameters  = data['enc']['parameters']
    end

    def to_s
      @name
    end

    def data
      {
          'name'        => @name,
          'classes'     => @classes,
          'parameters'  => @parameters,
          'environment' => @environment,
      }
    end

    def to_json
      data.to_json
    end
  end
end