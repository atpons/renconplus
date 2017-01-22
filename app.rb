require 'eventmachine'
require "docker-api"
require "sinatra"
require "dotenv"
require "omniauth-twitter"
require "twitter"
require "json"
require "net/http"
require "yaml"

Docker.url = ENV["DOCKER_HOST"]
set :environment, :production
set :bind, '0.0.0.0'

def fill(str)
  if str.nil?
    return []
  else
    return str
  end
end


def empty(str)
  case str.empty?
  when true
    return []
  else
    return str.split(/\s*,\s*/)
  end
end

class Container
  def initialize(id,image,env,cmd,memory,port)
    @id = id
    @image = image
    @env = empty(env)
    @cmd = empty(cmd)
    @memory = memory
    @available_memory = {"128MB" => 134217728}
    @memory = memory
    @port = port
    @exp_port = Hash.new
    @bind_port = Hash.new
    empty(port).each do |p|
      @exp_port["#{p}/tcp"] = {} 
    end
    empty(port).each do |p|
      @bind_port["#{p}/tcp"] = [{}]
    end
  end
  def run
    EM.defer do
      @pull_image = Docker::Image.create('fromImage' => @image)
      @container = Docker::Container.create(
        'Image' => @image,
        "Labels" => {"com.rencon.atpons.userid"=> @id },
        'Env' => @env,
        'Cmd' => @cmd,
        'ExposedPorts' => @exp_port,
        'HostConfig' => { "CpuShares" => 1024, "Memory" => @available_memory[@memory] , 'Privileged' => true, 'PortBindings' => @bind_port
      }
      )
      @container.start
    end
  end
end

# Loading env
Dotenv.load
if ENV["TWITTER_CONSUMER_KEY"] == "" || ENV["TWITTER_CONSUME_SECRET"] == ""
  puts "You must put Twitter API Keys to .env file, please visit: https://apps.twitter.com"
  exit
end

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
  @title = "Login"
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
  @cont = Docker::Container.all(filters: { label: [ "com.rencon.atpons.userid=#{twitter.user.id}" ] }.to_json)
  erb :index
end

post "/run" do
  @title = "Run"
  @oauth = session[:twitter_oauth]
  @id = twitter.user.id.to_s
  container = Container.new(@id,@params[:image],@params[:environment],@params[:command],@params[:memory],@params[:port])
  container.run
  erb :run
end

post "/import_yaml" do 
  @title = "Import Docker Compose File"
  @oauth = session[:twitter_oauth]
  @screen_name = twitter.user.screen_name
  @id = twitter.user.id.to_s
  @file = Net::HTTP.get URI.parse(@params[:uri].to_s)
  yaml = YAML.load(@file)
  yaml.each{|key,val|
    unless val["environment"].nil?
    val["environment"].each do |x|
      @env = x.join("=")
    end
    else
      @env = []
    end
    container = Container.new(@id,val["image"],@env,fill(val["command"]).split,@params[:memory],fill(val["ports"]))
  }
  erb :run
end

get "/import" do
    @oauth = session[:twitter_oauth]
  @screen_name = twitter.user.screen_name
  @id = twitter.user.id.to_s
  erb :import
end

get "/admin" do
  @title = "Admin"
  if ENV["ADMIN_TWITTER_USER_ID"].to_s == twitter.user.id.to_s
    @images = Docker::Image.all
    @cont = Docker::Container.all()
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

get "/wipe" do
  if ENV["ADMIN_TWITTER_USER_ID"].to_s == twitter.user.id.to_s
    Docker::Container.all(all: true, filters: { status: ["exited","dead"] }.to_json).each do |i|
      i.remove
    end
    Docker::Image.all(all: true, filters: { dangling: ["true"] }.to_json).each do |i|
      i.remove
    end
    redirect "/"
  else
    redirect "/"
  end
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
