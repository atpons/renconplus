require "docker-api"
require "sinatra"

Docker.url = "http://127.0.0.1:4243/"
cons = Docker::Container.all(:running => true)
cont = Docker::Container.all(:running => true)


@CID = []
@PORT = []
@IMG = []
@CNAME = []


cons.each do |con|
  begin
  @PORT.push(con.json["NetworkSettings"]["Ports"])
  rescue
  else
  end
@IMG.push(con.json["Config"]["Image"])
@CID.push(con.json["Id"])
@CNAME.push(con.json["Name"])
end

image = Docker::Image.all
image.each do |img|
  puts img.json["RepoTags"]
end
puts @CID
puts @IMG
puts @CNAME
puts @PORT

get "/" do
  :erb index
end
