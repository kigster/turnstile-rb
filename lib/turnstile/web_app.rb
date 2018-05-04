require 'sinatra'
require_relative 'dependencies'
require 'json'
module Turnstile
  class WebApp < ::Sinatra::Base
    SUPPORTED_FORMATS = %i(yaml json nad)
    set :port, Turnstile.config.port

    include Dependencies

    set :sessions, false
    set :port, Turnstile.config.port

    get '/turnstile/:format' do
      fmt = params['format'].to_sym
      if SUPPORTED_FORMATS.include?(fmt)
        status 200
        headers 'Content-type' => fmt.to_s
        body aggregate.send("to_#{fmt}".to_sym)
      else
        status 500
        body "Error: unsupported format #{fmt}!"
      end
    end

    # start the server if ruby file executed directly
    run!
  end
end
