# TanitBlog

TanitBlog is a small static blog engine written in ruby.
It is designed to be very light and very simple.

There is no database : data are stored in plain text files, and metadata in a YAML frontmatter in each file.
It use Markdown syntax and Slim template language to make post creation simple, despite it's only a command line tool.

## Installation

Just put `tanitblog.rb` in your path and set the configuration file (see below).

Of course, you need the ruby interpretor and rubygem.
A few gems are also required :

  `gem install slim redcarpet unidecoder`

## Configuration

The configuration is stored in the file `/etc/tanitblog/tanitblog.conf`. You can provide an alternative file in the command line with the `-c` option.

Example (note this is YAML syntax):

```yaml
---
directories:
  posts: /etc/tanitblog/posts/                  # Directory holding the posts files.
  templates: /etc/tanitblog/templates/          # Directory holding the templates files, see 'templates' below.
  static: /etc/tanitblog/static/                # For static component, such images files or scripts.
  preview: /var/www/html/dev/                   # Preview web document root
  production: /var/www/html/prod/               # Production web document root

templates:
  post: post.slim                               # Template filename for index.html
  index: index.slim                             # Template filename for each posts

pretty_html: true                               # Make the HTML indented
```

Don't forget to point out your web server to the production and preview directories.

## Usage

Once you've created all directories of your configuration file, create the two templates files: one for the index, one for each post.
Theses templates use [Slim syntax](http://slim-lang.com/). Check out `etc/template/*` for an example.

Inside each template, the following variables are available :

### Index

  - posts		: All posts, sorted by date
  - posts_by_years	: A hash with all posts, group by years
  - posts_by_tags 	: A hash with all posts, group by tags

### Posts

  - self 		        : The current post
  - previous_post  	: The previous post, by date
  - next_post 	    : The next post, by date
  - posts_by_years	: A hash with all posts, group by years
  - posts_by_tags 	: A hash with all posts, group by tags

Then, create a file containing your post, in Markdown, with this YAML frontmatter :

```yaml
---
title: My first article with TanitBlog
date: 20120628
tags:
 - ruby
 - blog
---
This is Markdown content
========================
See http://daringfireball.net/projects/markdown/syntax for syntax.
```

Put it in the `posts/` directory, the name of the file does'nt matter but it must have a `.md` suffix.
The `date` field could be everything understood by the ruby `Date.parse()` method. See [Ruby Date class](http://ruby-doc.org/stdlib-2.0.0/libdoc/date/rdoc/Date.html) for details.

Finally, and each time you will modify or add a post, populate the blog with the command `./tanitblog.rb --generate`
This will create all HTML files in the preview directory.

If everything is fine, publish it with `./tanitblog.rb --publish` . The previously generated content will be copied in the production directory.

Be carefull, the content of the preview and production directories are deleted and re-created each time. Put your static stuff in the `static` directory.

## License

Copyleft 2013 - Nicolas AGIUS
Released under GNU/GPLv3 License.

