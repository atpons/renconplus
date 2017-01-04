require 'eventmachine'
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
  @title = "Login"↲   
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
  @img = @params[:image]
  @environment = empty(@params[:environment])
  @command = empty(@params[:command])
  @exp_port = Hash.new
  @bind_port = Hash.new
  empty(@params[:port]).each do |p|
    @exp_port["#{p}/tcp"] = {} 
  end
  empty(@params[:port]).each do |p|
    @bind_port["#{p}/tcp"] = [{}]
  end
  EM.defer do
    @pull_image = Docker::Image.create('fromImage' => @img)
    @container = Docker::Container.create(
      'Image' => @img,
      "Labels" => {"com.rencon.atpons.userid"=> twitter.user.id.to_s },
      'Env' => @environment,
      'Cmd' => @command,
      'ExposedPorts' => @exp_port,
      'HostConfig' => { 'Privileged' => true, 'PortBindings' => @bind_port
      }
    )
    @container.start
  end
  erb :run
end

get "/admin" do
  @title = "Admin"
  if ENV["ADMIN_TWITTER_USER_ID"].to_s == twitter.user.id.to_s
    @images = Docker::Image.all
    @cont = Docker::Container.all(all: true)
  else
    redirect "/"
  end
  erb :admin
end

get "/stop" do
  @title = "Stop"
  @id = @params[:id]
  @container = Docker::Container.get(@id)
  @container.stop
  erb :stop
end

post "/delete" do
  @title = "Delete"
  @name = params[:image]
  Docker::Image.all.each do |i|
    if i.json["RepoTags"].any?
      if i.json["RepoTags"][0] == @name
        @id = i.json["Id"]
        else
      end
    end
  end
  image = Docker::Image.get(@id)
  image.remove(:force => true)
  redirect "/"
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
