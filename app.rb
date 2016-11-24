require "docker-api"
require "sinatra"

set :bind, '0.0.0.0'
# [Important] Please setup your Docker Host
Docker.url = "http://127.0.0.1:4243/"


get "/" do
  @image = Docker::Image.all
  cons = Docker::Container.all(:running => true)
  @cont = Docker::Container.all(:running => true)
  erb :index
end

post "/run" do
  @img = @params[:img]
  @container = Docker::Container.create(
    'Image' => @img,
    'ExposedPorts' => { '80/tcp' => {} },
    'HostConfig' => { 'Privileged' => true, 'PortBindings' => {
      '80/tcp' => [{}]
    }}
  )
  @container.start
  erb :run
end

get "/stop" do
  @id = params["id"]
  @container = Docker::Container.get(@id)
  @container.stop
  erb :stop
end
