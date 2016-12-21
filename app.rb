require "docker-api"
require "sinatra"
require "dotenv"
require "omniauth-twitter"
require "twitter"
require "json"

def empty(str)
   case str.empty?
   when true
       return []
   else
       return str.split(/\s*,\s*/)
   end
end

# Loading env
Dotenv.load
if ENV["TWITTER_CONSUMER_KEY"] == "" || ENV["TWITTER_CONSUME_SECRET"] == ""
  puts "You must put Twitter API Keys to .env file, please visit: https://apps.twitter.com"
  exit
end


set :environment, :production
set :bind, '0.0.0.0'
Docker.url = ENV["DOCKER_HOST"]

configure do
  enable :sessions
  use OmniAuth::Builder do
    provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  end
end

helpers do
  def logged_in?
    session[:twitter_oauth]
  end

  def twitter
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = session[:twitter_oauth][:token]
      config.access_token_secret = session[:twitter_oauth][:secret]
    end
  end
end

before do
  pass if request.path_info =~ /^\/auth\//
  redirect to('/auth/not_logged_in') unless logged_in?
end

get "/auth/not_logged_in" do
  erb :not_logged_in
end

after do
  
end

get '/auth/twitter/callback' do
  session[:twitter_oauth] = env['omniauth.auth'][:credentials]
  redirect to('/')
end

get '/auth/failure' do
end

get "/" do
  @oauth = session[:twitter_oauth]
  @screen_name = twitter.user.screen_name
  @title = "Top"
  @image = Docker::Image.all
  @cont = Docker::Container.all(all: true, filters: { label: [ "com.rencon.atpons.userid=#{twitter.user.id}" ] }.to_json)
  erb :index
end

post "/run" do
  @title = "Run"
  @oauth = session[:twitter_oauth]
  @img = @params[:img]
  @environment = empty(@params[:environment])
  @command = empty(@params[:command])
  @container = Docker::Container.create(
    'Image' => @img,
    "Labels" => {"com.rencon.atpons.userid"=> twitter.user.id.to_s },
    'Env' => @environment,
    'Cmd' => @command,
    'ExposedPorts' => { '80/tcp' => {} },
    'HostConfig' => { 'Privileged' => true, 'PortBindings' => {
      '80/tcp' => [{}]}
    }
  )
  @container.start
  erb :run
end

get "/admin" do
  if ENV["ADMIN_TWITTER_USER_ID"].to_s == twitter.user.id.to_s
     @images = Docker::Image.all
  else
    redirect "/"
  end
erb :admin
end

get "/stop" do
  @title = "Stop"
  @id = params["id"]
  @container = Docker::Container.get(@id)
  @container.stop
  erb :stop
end

error do
  @title = "Error"
  @error = env["sinatra.error"].message
  erb :error
end

get '/logout' do
  session.clear
  redirect to('/')
end
