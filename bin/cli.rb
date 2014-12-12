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
require 'slop'
require 'yaml'

module Automaton
  class CLI

    def initialize
      @command_options = ARGV[1].to_s
      command_array = ['add', 'update', 'remove']

      # Option Parsing, and Subcommands
      @opts = Slop.new(:help=>true) do

        command_block = Proc.new {
          command_array.each do |ele|
            command ele do
              description "#{ele} a node or element"
              on :n,:name, "Node or Instance Name to #{ele}", :argument => :required
              on :e,:environment, 'The Environment the node is a part of', :argument => :required
              on :c,:classes=, 'Classes that should be applied to the node', :as => String
              on :p,:parameters=, 'Parameters that should be applied to the node', :as => String
              on :i,:inherits=, 'The Node from which to inherit classes', :as => String
            end
          end
        }

        banner "usage: #{$0} [command] [options]\n"

        on :v, :verbose, 'Enable verbose mode'
        on :d, :debug, 'Enable debug mode'

        command 'lookup' do
          description 'Look up a node by name and return class information'
          on :n,:name, 'The name or FQDN of the node you want to lookup', :argument => :required
        end

        command_block.call

        command 'facts' do
          description 'Retrieves and Keeps Facts up to date'
          on :n,:name, 'Node or Instance Name to collect facts for', :argument => :required
          on :u,:update, 'Flag to update facts instead of retrieval'
        end

      end

      # Parse Arguments
      begin
        @opts.parse
      rescue Slop::Error => e
        puts e.message
        puts @opts # print help
      end

      #Set Commands
      @command     = @opts.parse[0].to_s.empty? ? @opts : @opts.parse[0].to_sym
      @cmd         = @opts.fetch_command(@command)

      #Set Global Options
      debug        = true if @opts.d?
      verbose      = true if @opts.v?

      # Set from command line logging
      Automaton::Log::from_cli(is_debug = debug, is_verbose = verbose, is_cli = true)
    end

    def data
      cmd  = @opts.fetch_command(@command)
      data = { :node => cmd[:name],
               :enc => {
                   :environment => cmd[:environment],
                   :classes     => cmd[:classes],
                   :parameters  => cmd[:parameters]
               },
               :inherit => cmd[:inherits]
      }
      return data
    end

    def classifier
      return print "#{@opts}\n" if @command_options.empty?
      return if @command_options == "-h" || @command_options == "--help"
      return print Automaton::Node.new(data).send(@command.to_s).to_yaml if @command.to_s == 'lookup'
      return Automaton::Node.new(data).send(@command.to_s) unless @cmd.nil?
    end

  end

  CLI.new.classifier

end
