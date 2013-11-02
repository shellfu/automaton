require_relative '../lib/node'
require_relative '../lib/automaton_routes'
require 'sinatra/base'
require 'json'

module Automaton
  class ENC < Sinatra::Base

    def log(severity, message)
      { severity => message }.to_json
    end

    def data
      { :node => params[:name],
        :enc => {
            :environment => params[:environment],
            :classes     => params[:classes],
            :parameters  => params[:parameters]
        },
        :inherit => params[:inherits]
      }
    end

    register Sinatra::AutomatonRoutes

    run! if app_file == $0

  end
end