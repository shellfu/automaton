require 'yaml'
module Automaton
  class HashHelper
    def self.str2hash(string, delimiter, type)
      case type
        when 'class'
          Hash[string.split(',').map { |s| k, *v = s.split(delimiter); [k, v.empty? ? nil : Hash[v.map { |str| str.split('=') }.inject({}) { |c, (key, v)| c[key] = v; c }]] }]
        when 'parameter'
          Hash[string.split(',').map { |str| str.split(delimiter) }.inject({}) { |c, (key, v)| c[key] = v; c }]
        else
          raise ArgumentError "Type #{ type } not supported!"
      end
    end
  end
end



