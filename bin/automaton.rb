require_relative '../lib/enc_methods'
require 'sinatra/base'
require 'json'

module Automaton
  class ENC < Sinatra::Base

    configure :production, :development do
      enable :logging
    end

    enc = Automaton::ENCMethods::new

    get '/node' do
      content_type :json
      node = enc.lookup(params[:name])
      if node == 'not_found'
        logger.error "Node >#{ params[:name] }< NOT Found in ENC"
        body "ERROR: Node >#{ params[:name] }< NOT Found in ENC"
        status 404
      else
        body node.to_json
        status 200
      end
    end

    get '/node/facts' do
      content_type :json
      node = enc.find_facts(params[:name])
      if node
        status 200
        body node.to_json
      else
        status 404
        logger.info "Node Facts for >#{ params[:name] }< Not Found"
        body "Node Facts for >#{ params[:name] }< NOT Found"
      end
    end

    post '/node/add' do
      node = enc.add(params[:name], params[:environment], params[:classes], params[:parameters], params[:inherit])
      if node == 'existing_entry'
        status 404
        logger.error "Node >#{ params['name'] }< already exists in the ENC"
        body "ERROR: Node >#{ params['name'] }< already exists in the ENC"
      else
       status 200
       logger.info "Node >#{ params[:name] }< Added to the ENC"
       body "Node >#{ params[:name] }< Added to the ENC"
      end
    end

    post '/node/update' do
      begin
        enc.update(params[:name], params[:environment], params[:classes], params[:parameters], params[:inherit])
        logger.info "Node >#{ params[:name] }< has been updated"
        body "Node >#{ params[:name] }< has been updated"
        status 200
      rescue
        status 404
        logger.error "Node >#{ params[:name] }< NOT Found in ENC"
        body "ERROR: Node >#{ params[:name] }< NOT Found in ENC"
      end
    end

    post '/node/remove' do
      content_type :text
      node = enc.remove(params[:name], nil, nil)
      if node == 'not_found'
        status 404
        logger.error "Node >#{ params[:name] }< NOT Found in ENC"
        body "ERROR: Node >#{ params[:name] }< NOT Found in ENC"
      else
        status 200
        logger.info "Node >#{ params[:name] }< REMOVED from the ENC"
        body "Node >#{ params[:name] }< REMOVED from the ENC"
      end
    end

    post '/node/remove/class' do
      begin
        if params[:classes]
          enc.remove(params[:name], params[:classes], nil)
          status 200
          logger.info "Class >#{ params[:classes] }< REMOVED from the ENC"
          body "Class >#{ params[:classes] }< REMOVED from the ENC"
        else
          raise 404
        end
      rescue
        status 404
        logger.error "Class >#{ params[:classes] }< NOT Found in ENC"
        body "ERROR: Class >#{ params[:classes] }< NOT Found in ENC"
      end
    end

    post '/node/remove/parameter' do
      begin
        if params[:parameters]
          enc.remove(params[:name], nil, params[:parameters])
          status 200
          logger.info "Parameter >#{ params[:parameters] }< REMOVED from the ENC"
          body "Parameter >#{ params[:parameters] }< REMOVED from the ENC"
        else
          raise 404
        end
      rescue
        status 404
        logger.error "Parameter >#{ params[:parameters] }< NOT Found in ENC"
        body "ERROR: Parameter >#{ params[:parameters] }< NOT Found in ENC"
      end
    end

    run! if app_file == $0
  end
end