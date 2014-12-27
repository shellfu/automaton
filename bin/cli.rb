#!/usr/bin/env ruby
# ***********************************************************************
# GPL License
# ***********************************************************************
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
#************************************************************************
#
# author => Daniel Kendrick
# email  => info@shellfu.com
# web    => http://www.shellfu.com
#
require_relative '../lib/node'
require_relative '../lib/fact'
require 'slop'
require 'yaml'

module Automaton
  class Global_Options
    def self.common(command)
      command.on :n,:name, "Node or Instance Name to add/update/remove", :argument => :required
      command.on :e,:environment, 'The Environment the node is a part of', :argument => :required
      command.on :c,:classes=, 'Classes that should be applied to the node', :as => String
      command.on :p,:parameters=, 'Parameters that should be applied to the node', :as => String
      command.on :i,:inherits=, 'The Node from which to inherit classes', :as => String
    end

    def self.lookup(command)
      command.on :n,:name, 'The name of the node to lookup', :argument => :required
    end
  end

  class Parse_Command_Line_Arguments
    def initialize
      @command_options = ARGV[2].to_s
      @sub_command = ARGV[1].to_s
      @opts = Slop.new(:help=>true) do
        banner "usage: #{$0} [command] -n <node_name> [options]\n"

        on :v, :verbose, 'Enable verbose mode'
        on :d, :debug,   'Enable debug mode'

        on :version, 'Display automaton version' do
          puts "0.2.3"
        end

        ['add', 'update', 'remove'].each do |ele|
          command ele do
            description "#{ele} a node or element"
            banner "\nusage: #{$0} #{ele} -n <node_name> [options]\n"
            Global_Options.common(self)
          end
        end

        command 'lookup' do
          description 'Look up a node by name and return class information'
          banner "\nusage: #{$0} lookup -n <node_name>\n"
          Global_Options.lookup(self)
        end

        command 'fact' do
          description "fact collect and fact lookup commands"
          banner "\nusage: #{$0} fact lookup -n <node_name> -f [<fact_name>|ALL]\nusage: #{$0} fact collect -n <node_name>\n"
          Global_Options.lookup(self)
          on :f,:fact=, 'The fact name to lookup or ALL', :as => String, :argument => :required
          run { |opts, args| @sub_command = args.shift }
        end
      end
      parse_arguments
    end

    def parse_arguments
      # Parse Arguments
      begin
        options = @opts.parse
      rescue Slop::Error => e
        puts e.message
        puts @opts # print help
      end
      #Set Commands
      @command = options[0].to_s.empty? ? options : options[0].to_sym
      @command_hash = @opts.fetch_command(@command)

      # Set from command line logging
      Automaton::Log::from_cli(is_debug = (true if @opts.d?), is_verbose = (true if @opts.v?), is_cli = true)
    end

    def fact_data
      { :node => @command_hash[:name],
               :sub_command => @sub_command,
               :fact_name => @command_hash[:fact]
      }
    end

    def node_data
      { :node => @command_hash[:name],
               :enc => {
                   :environment => @command_hash[:environment],
                   :classes     => @command_hash[:classes],
                   :parameters  => @command_hash[:parameters]
               },
               :inherit => @command_hash[:inherits]
      }
    end

    def return_commands
      return print "#{@opts}\n" if @command_options.empty? unless @opts.version?
      return if @command_options == "-h" || @command_options == "--help"
      return print Automaton::Node.new(node_data).send(@command.to_s).to_yaml if @command.to_s == 'lookup'
      return Automaton::Fact.new(fact_data).send(@command.to_s) if @command.to_s == 'fact'
      return Automaton::Node.new(node_data).send(@command.to_s) unless @command_hash.nil?
    end

  end

  Parse_Command_Line_Arguments.new.return_commands

end
