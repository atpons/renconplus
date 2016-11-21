require "docker"

Docker.url = "http://127.0.0.1:2375/"
cons = Docker::Container.all(:running => true)
cons.each do |con|
  puts con.id
end
