require 'sinatra'

puts "Starting status page server"

module TellaPeer
  class StatusPage < Sinatra::Base

    set :static, true                             # set up static file routing
    set :public_dir, File.expand_path('../public', __FILE__) # set up the static dir (with images/js/css inside)
    
    set :views,  File.expand_path('../views', __FILE__) # set up the views dir
    
    # Your "actions" go here…
    #
    get '/' do
      erb :index
    end
    
  end

  Thread.new { StatusPage.run! }
end