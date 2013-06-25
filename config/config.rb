require 'yaml'

module Automaton
  # This Class reads config/config.yml and parses output into a hash
  # config.yml must exist in config directory under Automaton.
  class Configure
    def self.config(file = "#{File.dirname(__FILE__)}/config.yml")
      if File.exists?(file)
        YAML.load_file(file).inject({}){|config,(key,value)| config[key.to_sym] = value; config}
      else
        puts 'config.yml does not exist! Please create it, and try again.'
        exit
      end
    end
  end
end
