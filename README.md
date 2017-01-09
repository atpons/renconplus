Rencon Plus
======================
Rencon Plus is providing Container as a Service.
This project is forked by atpons/rencon.
It is provided by Docker, Ruby, Sinatra, [swipely/docker-api](https://github.com/swipely/docker-api).

Installation
------
### Requirement
+ Docker
+ Ruby 2.3+
+ Sinatra
#### Gems
+ docker-api
+ dotenv
+ eventmachine
+ omniauth
+ passenger

Please read `Gemfile` for some dependence gems.

### Enable Docker Remote API
If you only installed Docker, you can't use Rencon.

You must enable Docker Remote API and it can access to Docker from RESTful API.

#### Ubuntu 16.04 LTS
    sudo vi /lib/systemd/system/docker.service
and you modify the line:

    ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:4243
and you run:

    systemctl daemon-reload
    sudo service docker restart
and you can test:

    curl http://localhost:4243/version


Using Rencon
-------------
### Run
**IMPORTANT:** You must modify `.env` if your Docker API endpoint is not `http://localhost:4243/`.

First, you need `bundle install`, and `app.rb` is Rencon Application.

Second, you need modify `.env` to Twitter Consumer Key / Consumer Secret / Administrator Twitter ID (Integer).

Third, we can run it on Passenger.

#### Passenger on Apache2
Please run `passenger-install-apache2-module` and you add snippet to `httpd.conf`.

And you need set `DocumentRoot` to `/public` and we can use it.

Maybe you can run any containers from Docker Hub.

License
--------
Please read: `LICENSE`.
