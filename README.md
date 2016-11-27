Rencon
======================
Rental Container with prepared CMS.
It is provided by Docker, Ruby, Sinatra, [swipely/docker-api](https://github.com/swipely/docker-api).

Installation
------
### Requirement
+ Docker
+ Ruby 2.3+
+ Sinatra
+ swipely/docker-api
+ dotenv

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

You can run with `ruby app.rb` and getting started.

If you provide Rencon, you will use a reverse proxy: nginx, Apache, Unicorn.

Image Compabilities for Rencon (Docker Hub)
------------------------------
+ `tutum/wordpress`
+ `drupal`

Maybe you can run any containers from Docker Hub.

License
--------
Please read: `LICENSE`.
