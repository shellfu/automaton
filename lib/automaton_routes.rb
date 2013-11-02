require 'sinatra/base'

module Sinatra
  module AutomatonRoutes

    def self.lookup(app)
      app.get '/lookup' do
        content_type :json
        node = Automaton::Node.new(data).lookup
        return status(404), body( log('info',"Node >#{params[:name]}< not found") ) if node.nil?
        body node.to_json
        status 200
      end
    end

    def self.update(app)
      app.post %r{/(add|update)$} do
        begin
          node = Automaton::Node.new(data).send(params[:captures][0])
          return status(200), body( log('info',">#{params[:name]}< updated") ) if node[0] == 'successful'
          return status(409), body( log('warning', ">#{params[:name]}< exists") ) if node[0] == 'entry_exists'
        rescue
          return status(500), body( log('error', 'Check node for validity') )
        end
      end
    end

    def self.remove(app)
      app.post '/remove' do
        content_type :text
        node = Automaton::Node.new(data).remove
        return status(404), body( log( 'warning', ">#{ params[:name] }< NOT Found") ) if node == 'not_found'
        return status(200), body( log('info', ">#{ params[:name] }< removed or item removed") )
      end
    end


    def self.registered(app)
      lookup(app)
      update(app)
      remove(app)
    end

  end

  register AutomatonRoutes # for non modular apps, just include this file and it will register

end