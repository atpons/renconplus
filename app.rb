require "docker-api"

Docker.url = "http://127.0.0.1:4243/"
cons = Docker::Container.all(:running => true)

cons.each do |con|
  puts con.json["Config"]["Image"]
end
