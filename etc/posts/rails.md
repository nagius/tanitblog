---
title: Quick Ruby On Rail memo
date: 20160627
tags:
 - Linux
 - Ruby
 - Rails
---

Because I always forgot all these steps, the following commands will set up a ruby environment with RVM for a new Ruby On Rails project.
All these examples have been run on CentOS, feel free to adapt to others distribution !

# Install RbEnv

You can run this as you non-root user.

```
sudo yum install git gcc gcc-c++ sqlite-devel openssl-devel readline-devel zlib-devel v8
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
source ~/.bash_profile
```

You can also disable the documentation generation to save some time when installing and updating gems :


```
echo "gem: --no-document" >> ~/.gemrc
```

# Install Ruby and Rails in the project directory

```
mkdir myproject
cd myproject
echo "2.2.4" > .ruby-version
rbenv install
gem install rails
gem install bundler
```

# Create a new project

```
rails new ../myproject --skip-test-unit
```

Then you need to edit the Gemfile to adjust some dependancies. Edit `myproject/Gemfile` :

 - Uncomment the line `gem 'therubyracer',  platforms: :ruby`
 - Add the line `gem 'jquery-ui-rails'` if you want to use JQuery UI.


and update Gem dependancies :

```
bundle install
```

## Create a new controler

```
rails generate controller Calendar index --no-test-framework
```

## Create a new component

```
rails generate scaffold User name:string phone:string active:boolean Team:belongs_to --no-test-framework
```

# Run it !

## Run in development 

Before starting Rails you need to update the database schema.

```
bundle exec rake db:migrate
bundle exec rails server -b 0.0.0.0
```

You application will be listening on the port 3000.

## Run in production with Nginx and Puma

Puma is the preferred application server for Rails and it's already shipped and configured with Rails 5. You can find more configuration option in `config/puma.rb`.
We will also use Nginx as reverse proxy. It's useful to provide for example SSL or authentication. This example will use Centos 7 for convenience, adapt to your favorite distribution.


Usually, you would manage your source files with Git, so you would clone the repo in /srv/www/ for example.

## Install Nginx

```
yum install epel-release
yum install nginx
```

We will create a deploy user to run the application.

```
sudo useradd -d /srv/www/ -g nginx deploy
chmod 750 /srv/www
su - deploy
# clone the application here (/srv/www/)
cd myproject
```

# Install rbenv

```
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
source ~/.bash_profile
echo "gem: --no-document" >> ~/.gemrc
```

# Install Ruby and Initialize the Rails application

```
rbenv install
gem install bundle
bundle install
bundle exec rake db:setup RAILS_ENV=production
bundle exec rake assets:precompile
```

Then, exit deploy's shell to switch back to root.

## Configure systemd services:

 - `/etc/systemd/system/puma.service`

```
[Unit]
Description=Puma Application Server
Requires=network.target

[Service]
Type=simple
User=deploy
Group=nginx
WorkingDirectory=/srv/www/myproject
ExecStart=/usr/bin/bash -lc 'bundle exec --keep-file-descriptors puma -e production -b unix:///srv/www/myproject/puma.sock'
Restart=always

[Install]
WantedBy=multi-user.target
```

The trick here is to use `bash -lc` in ExecStart. That will load all the environment configuration of the deploy user, including rbenv.

Start Puma with:

```
systemctl start puma
```

### Configure Nginx

 - /etc/nginx/conf.d/myproject.conf :

```
server {
		# Cache and direct serving for static content
        location ^~ /assets/ {
            gzip_static on;
            expires max;
            add_header Cache-Control public;
            alias /srv/www/myproject/public/assets/;
        }

        location / {
                proxy_pass http://unix:/srv/www/myproject/puma.sock:;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_redirect off;
        }
}
```

Start Nginx with :

```
systemctl nginx restart
```

With this setup, all the assets are precompiled and served as static content directly by Nginx. This help scaling as Puma will be free from this task.
You can now browse your application at http://myserver/ !

Application log will be available through Systemd with `journalctl`.

