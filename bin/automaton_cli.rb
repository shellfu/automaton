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
  # ------------------------------------------
  # Option Parsing, and Subcommands
  # ------------------------------------------
  opts = Slop.new(:help=>true) do
    banner "usage: #{$0} [command] [options]\n"

    on :v, :verbose, 'Enable verbose mode'
    on :d, :debug, 'Enable debug mode'

    command 'lookup' do
      description 'Look up a node by name and return class information'
      on :n,:name, 'The name or fqdn of the node you want to lookup', :argument => :required
    end

    command 'add' do
      description 'Add a node to the ENC'
      on :n,:name, 'Node or Instance Name to Add', :argument => :required
      on :e,:environment, 'The Environment the node is a part of', :argument => :required
      on :c=,:classes=, 'Classes that should be applied to the node', :as => String
      on :p=,:parameters=, 'Parameters that should be applied to the node', :as => String
      on :i=,:inherits=, 'The Node from which to inherit classes', :as => String
    end

    command 'update' do
      description 'Update a node in the ENC'
      on :n,:name, 'Node or Instance Name to Update', :argument => :required
      on :e,:environment, 'The Environment the node is a part of', :argument => :required
      on :c=,:classes=, 'Classes that should be applied to the node', :as => String
      on :p=,:parameters=, 'Parameters that should be applied to the node', :as => String
      on :i=,:inherits=, 'The Node from which to inherit classes', :as => String
    end

    command 'remove' do
      description 'Removes a node in the ENC'
      on :n,:name, 'Node or Instance Name to Remove', :argument => :required
      on :c=,:classes=, 'Classes that should be removed from the node', :as => String
      on :p=,:parameters=, 'Parameters that should be removed from the node', :as => String
    end

    command 'facts' do
      description 'Retrieves and Keeps Facts up to date'
      on :n,:name, 'Node or Instance Name to collect facts for', :argument => :required
      on :u,:update, 'Flag to update facts instead of retrieval'
    end
  end

  opts.parse!

  # ------------------------------------------
  # Command Execution
  # ------------------------------------------
  #enc = Automaton::ENCMethods::new({} )
  #enc = Automaton::ENCMethods::new
  #{ 'node' => @name,
  #  'enc' => {
  #      'environment' => @env,
  #      'classes'     => @classes,
  #      'parameters'  => @params
  #  },
  #  'inherit' => @inherits
  #}
  debug   = true if opts.d?
  verbose = true if opts.v?
  Automaton::Log::from_cli(is_debug = debug, is_verbose = verbose, is_cli = true)

  add = opts.fetch_command(:add)
  Automaton::Node::new({ :node => add[:name],
                                 :enc => {
                                   :environment => add[:environment],
                                   :classes     => add[:classes],
                                   :parameters  => add[:parameters]
                                 },
                                 :inherit => add[:inherits]
                             }).add if add.name?

  remove = opts.fetch_command(:remove)
  Automaton::Node::new({ :node => remove[:name],
                               :enc => {
                                 :environment => remove[:environment],
                                 :classes     => remove[:classes],
                                 :parameters  => remove[:parameters]
                               },
                               :inherit => remove[:inherits]
                            }).remove if remove.name?

  update = opts.fetch_command(:update)
  Automaton::Node::new({ :node => update[:name],
                               :enc =>{
                                 :environment => update[:environment],
                                 :classes     => update[:classes],
                                 :parameters  => update[:parameters],
                               },
                               :inherit => update[:inherits]
                             }).update if update.name?

  lookup = opts.fetch_command(:lookup)
  puts Automaton::Node::new({ :node => lookup[:name],
                                    :enc =>{
                                      :environment => lookup[:environment],
                                      :classes     => lookup[:classes],
                                      :parameters  => lookup[:parameters],
                                    },
                                    :inherit => lookup[:inherits]
                                  }).lookup.to_yaml if lookup.name?

  facts = opts.fetch_command(:facts)
  facts.update? ? enc.store_facts(facts[:name]) : (puts enc.find_facts(facts[:name])['facts'].to_yaml) if facts.name?
end
