---
title: Quick Sinatra boilerplate
date: 20150208
tags:
 - Linux
 - Ruby
 - Sinatra
---

This document describe the steps to setup a new Sinatra project. This web application will use a YAML configuration file and an asset pipeline.
All these examples have been run on CentOS, feel free to adapt to others distribution !

# Install Ruby and RVM

```
yum install git ruby ruby-devel

# Install RVM
curl -sSL https://get.rvm.io | bash -s stable

# Check requirement
rvm requirements

# Install ruby
rvm install 2.0.0

# Set default ruby
rvm use --default 2.0.0

# Create a new gemset
rvm gemset create my_project
rvm gemset use my_project

```

You can also disable the documentation generation to save some time when installing and updating gems :

 -  ~/.gemrc

```
install: --no-rdoc --no-ri
update:  --no-rdoc --no-ri
```

# RVM cheatsheet

```
# Update RVM
rvm get stable

# List available rubies
rvm list known

# List installed rubies
rvm list

# List gemset
rvm gemset list

# List all
rvm list gemsets

# List gems in the current gemset
gem list
```

# Create a new project

Once Ruby is setup with the version you need, it's time to create the project's tree.

## Create the directory structure

Assets will be served from app/js, app/css and app/images. See AssetPack documentation for more details.

```
mkdir my_project
cd my_project
mkdir -p app/js app/css app/images config views 
```

## Create framework files

I suggest you to use Bundler to manage all Gem dependencie.

 - Gemfile

```
source 'https://rubygems.org'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'sinatra-assetpack'
gem 'rake'
gem 'thin'
gem 'shotgun'
```

 - Rakefile

```
APP_FILE  = 'app.rb'
APP_CLASS = 'App'

require 'sinatra/assetpack/rake'
```

 - config.ru

```
require './app'
run App
```

## Create application files

 - config/config.yml

```
---
title: "My new Sinatra App"
```

 - views/layout.erb

```
<html>
<head>
	<%= css :app, :media => 'screen' %>
	<%= js  :app %>
	<title><%= settings.title %></title>
</head>
<body>
	<%= yield %>
</body>
</html>
```

 - views/index.erb

```
<H2>Sinatra is awsome !</H2>
```

 - app.rb

```
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/assetpack'

class App < Sinatra::Base
	set :root, File.dirname(__FILE__)

    register Sinatra::AssetPack
    register Sinatra::ConfigFile

	# Framework configuration
	configure :production, :development do
		set :show_exceptions, :after_handler
		enable :logging
	end

    # Asset pipeline configuration
    assets do
        js :app, [ '/js/*.js' ]

        css :app, [ '/css/*.css' ]

        js_compression  :jsmin    # :jsmin | :yui | :closure | :uglify
        css_compression :simple   # :simple | :sass | :yui | :sqwish
		prebuild true
    end

    # Application configuration
    config_file "config/config.yml"

    get '/' do
        erb :index
    end

end

# vim: ts=4:sw=4:ai:noet
```

# Run it !

Usually, you would manage your source files with Git, so just clone the repo in /srv/www/ for example.

## Install Sinatra and all dependancies

```
cd /srv/www/my_project
gem install bundle
bundle install
```

## Run in development 

```
shotgun -p 4567 -o 0.0.0.0
```

## Run in production with Nginx and Thin

One of the best way to run Ruby web application is to use Nginx as front server and Thin as application server.
Thin is lightweight and simple to configure. It's really efficient for small and medium setup.

### Configure Ruby

```
rvm alias create my_project ruby-2.0.0@my_project
rvm use my_project
rvm wrapper my_project thin
```

### Configure Thin

```
thin install
mv /etc/rc.d/thin /etc/init.d/
```

 - Edit /etc/init.d/thin and replace the DAMEON value by:

```
DAEMON="/usr/local/rvm/wrappers/my_project/thin"
```

 - Create the file /etc/thin/my_project.yml :

```
# /etc/thin/my_project.yml - Thin configuration file 
user: www-data
group: www-data
pid: /var/run/thin/my_project.pid
timeout: 30
wait: 30
log: /var/log/thin/my_project.log
max_conns: 1024
require: []
environment: production
max_persistent_conns: 512
servers: 1
onebyone: true
threaded: true
no-epoll: true
daemonize: true
socket: /var/run/thin/my_project.sock
chdir: /srv/www/my_project/
tag: my_project
prefix: /my_project

```

 - Start the daemon


```
chkconfig --level 345 thin on
chown www-data. /var/run/thin
/etc/init.d/thin start
```

### Configure Nginx

 - /etc/nginx/conf.d/my_project.conf :

```
server {
        listen 80;
        server_name myserver;

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        location /my_project/ {
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_redirect off;
                proxy_pass http://unix:/var/run/thin/my_project.0.sock:/my_project/;
        }
}
```

Now you can browse your awsome Sinata application at http://myserver/my_project/ !
