require_relative '../config/config'
require 'logger'

module Automaton
  class Log
    @config = Automaton::Configure::config

    def self.from_cli(is_debug = @config[:debug], is_verbose = @config[:verbose], is_cli = false)
      @is_debug    = is_debug
      @is_verbose  = is_verbose
      @is_cli      = is_cli
    end

    def self.msg(severity, msg)
      begin
        dir  = File.dirname(@config[:logpath])
        @log = Logger.new("#{ @config[:logpath] }", 'weekly')
      rescue
        puts 'Checking Log Path, and creating as needed'
        if Dir.exist?(dir)
          puts "#{@config[:logpath]} exists" if @config[:verbose] == 'true'
        else
          Dir.mkdir(dir)
          File.write(@config[:logpath], '')
        end
      end
      log = case severity
              when 'error'
                @log.error(msg)
              when 'warn'
                @log.warn(msg)
              when 'debug'
                @config[:debug] == 'true' ? @log.debug(msg) : nil
              else
                @config[:verbose] == 'true' ? @log.info(msg) : nil
            end
      Logger.new(STDOUT).info(msg) if @is_cli
      log
    end
  end
end