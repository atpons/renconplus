require "docker-api"
require "sinatra"
require "dotenv"

def empty(str)
   case str.empty?
   when true
       return ""
   else
       return str.split(/\s*,\s*/)
   end
end

Dotenv.load
set :environment, :production
set :bind, '0.0.0.0'
# [Important] Please setup your Docker Host
Docker.url = ENV["DOCKER_HOST"]

get "/" do
  @title = "Top"
  @image = Docker::Image.all
  cons = Docker::Container.all(:running => true)
  @cont = Docker::Container.all(:running => true)
  erb :index
end

post "/run" do
  @title = "Run"
  @img = @params[:img]
  @environment = empty(@params[:environment])
  @command = empty(@params[:command])
  @container = Docker::Container.create(
    'Image' => @img,
    'Env' => @environment,
    'Cmd' => @command,
    'ExposedPorts' => { '80/tcp' => {} },
    'HostConfig' => { 'Privileged' => true, 'PortBindings' => {
      '80/tcp' => [{}]
    }}
  )
  @container.start
  erb :run
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
