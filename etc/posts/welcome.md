---
title: Why this blog is'nt running Wordpress ?
date: 20131105
tags:
 - Ruby
 - Blog
---


Because, to fulfill my simple needs, I needed a simple tool and, of course, the most secure and performant one.
Traditional LAMP blog engines are too heavy and complicated for very simple needs as mine. And doing like everybody else is not interesting. 
As I'm a Linux hacker, I don't need any laggy WYSIWYG interface, a command line tool with Vim is far enough.

I wanted something revolutionary : a static blog !

## Why a static blog engine ?

Because it's really efficient and secure !

Performance are maximum : No need to regenerate same content again and again each time a visitor come to see it. Generate it once, and that's all !
Concerning security, this is the most secure website, as there is no code on server-side. No code, no attack.
Hosting is very simple, any stupid web server can run it, even Github ! No database, no bottleneck, just one command you run when you do an update.

So I've taken good ideas around here and started to wrote mine. It's now avaliable on [Github](https://github.com/nagius/tanitblog).

If you want a ready-to-use static engine, take a look at [Octopress](http://octopress.org/). It's really good, but it seems to me too complicated and too big for my simple needs. And write it's own tool is always a good training exercise !

## Under the hood

TanitBlog use some cool and well known stuff : Ruby, YAML, Markdown and Slim template engine.

I wrote it in Ruby, just because it's a fun language. Much more evolved than PHP. But I use plain Ruby, not Rails, because I wanted It very lightweight. No need of complex MVC architecture here.
Each post are stored in a standard plain text file, easy to version. Metadata are in the post itself, using a YAML frontmatter.
This method, also used by [Jekyll](http://jekyllrb.com/) and [Middleman](http://middlemanapp.com/) but not well known, is in fact very simple. Just put some variables in YAML at the begining of the file. Easy to manually write, easy to parse.

## Hosting

In the era of cloud computing, this website is self-hosted. Nginx is running on a RaspberryPi in my garage (many big companies started in a garage ! ) and powered by a small ADSL link with a limited upload bandwith... So be indulgent with the speed, maybe I'm sending a big mail !

And if it goes down for a few time, blame the cat who scratch the wire.



