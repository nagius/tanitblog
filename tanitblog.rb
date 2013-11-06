#!/usr/bin/env ruby

# tanitblog.rb - Static blog engine
# Copyleft 2013 - Nicolas AGIUS <nicolas.agius@lps-it.fr>

###########################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################

# TODO: use bundler

require 'rubygems'

require 'optparse' 
require 'slim'
require 'redcarpet'
require 'yaml'
require 'date'
require 'unidecoder'
require 'digest'
require 'ostruct'

# Local exception
class TanitException < Exception
end

# Taken from http://andreapavoni.com/blog/2013/4/create-recursive-openstruct-from-a-ruby-hash
# Could also use gem recursive-open-struct
class DeepStruct < OpenStruct
	def initialize(hash=nil)
		@table = {}
		@hash_table = {}

		if hash
			hash.each do |k,v|
				@table[k.to_sym] = (v.is_a?(Hash) ? self.class.new(v) : v)
				@hash_table[k.to_sym] = v

				new_ostruct_member(k)
			end
		end
	end

	def to_h
		@hash_table
	end

	def [](name)
		@table[name.to_sym]
	end

	def has_key?(name)
		@table.has_key?(name.to_sym)
	end
end

class Post
	attr_reader :title, :tags, :date
	
	# Renderer in static to avoid multiple instancation
	@@markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, 
		:autolink => true, 
		:space_after_headers => true
	)

	def initialize(file)
		puts "Parsing post: #{file} ..." if $DEBUG

		content = File.read(file)

		# Extract YAML frontmatter metadata
		if content =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
			@content = $'
			metadata = YAML.load($1)

			@title=metadata['title']
			@date=Date.parse(metadata['date'].to_s) # Will raise and ArgumentError if date is missing
			@tags=metadata['tags'] || [] # Default value to empty array if no tag defined

			raise TanitException, "Missing 'title' metadata" if @title.nil?
			raise TanitException, "Empty content" if @content.empty?
		else
			raise TanitException, "Wrong or empty file"
		end
	end

	# Generate HTML from markdown content
	def content
		@@markdown.render(@content)
	end

	# Stripped filename to fit in an URL. Should be unique.
	def urlname
		stripped_title=@title.to_ascii.downcase.strip.gsub(/[^-_a-z0-9]+/, '-')[0..30]
		"#{@date.strftime('%Y%m%d')}-#{stripped_title}.html"
	end

	# Uuid used by the show command
	def uuid
		Digest::MD5.hexdigest(@date.to_s + @title.to_s)
	end

	# Return the post in a parsable way with the YAML frontmatter
	def to_s
		metadata={
			"uuid" => self.uuid,
			"title" => @title,
			"urlname" => self.urlname,
			"date" => @date.strftime('%Y%m%d').to_i,
			"tags" => @tags
		}
			
		"#{metadata.to_yaml}\n---\n#{@content}"
	end
end


class Blog
	attr_reader :posts, :years, :tags

	def initialize(config_file)
		@posts=[]				# Full posts list, sorted by date
		@years=Hash.new			# Posts list, by years
		@tags=Hash.new			# Posts list, by tags
		@templates=Hash.new

		# Load confiuration
		@cfg=DeepStruct.new(YAML.load(File.read(config_file)))
			
		# Check all mandatories configuration variables
		{
			:templates => [ :post, :index ],
			:directories => [ :preview, :posts, :templates, :production, :static ]
		}.each { |root, leafs|
			if @cfg.has_key?(root)			
				leafs.each { |leaf|
					raise TanitException, "Missing #{root}.#{leaf} variable" unless @cfg[root].has_key?(leaf)
				}
			else
				raise TanitException, "Missing #{root} variables" unless @cfg.has_key?(root)
			end
		}

		# Check existence of directories
		@cfg.directories.to_h.each_value { |dir|
			raise TanitException, "Directory #{dir} not found" unless File.directory?(dir)
		}

		self.load()
	end

	# Return the previous post, nil if start reached
	def get_previous_post(post)
		i=@posts.index(post)
		if i == 0
			# Start reached, do not loop at the end
			nil
		else
			@posts[i-1]
		end
	end

	# Return the next post, nil if end reached
	def get_next_post(post)
		# return nil at the end
		@posts[@posts.index(post)+1]
	end

	# Get a post by its uuid
	def [](uuid)
		i=@posts.index{ |p| p.uuid==uuid }
		i.nil? ? nil : @posts[i]
	end

	# HTML render the index page
	def generate_index
		@templates[:index].render(nil, 
			:posts => @posts,
			:posts_by_years => @years,
			:posts_by_tags  => @tags
		)
	end

	# HTML render the specified post
	def generate_post(post)
		@templates[:post].render(post, 
			:previous_post  => self.get_previous_post(post),
			:next_post      => self.get_next_post(post),
			:posts_by_years => @years,
			:posts_by_tags  => @tags
		)
	end

	# Render and write the index file
	def write_index
		file=File.join(@cfg.directories.preview, "index.html")
		puts "Writing #{file} ..." if $DEBUG

		File.open(file, 'w') {|f| 
			f.write(self.generate_index)
		}
	end

	# Render and write all posts, one file for each
	def write_all_posts
		@posts.each { |post|
			file=File.join(@cfg.directories.preview, post.urlname)
			puts "Writing #{file} ..." if $DEBUG

			File.open(file, 'w') {|f| 
				f.write(self.generate_post(post))
			}
		}
	end

	# Empty the preview dir and copy static files
	def clear_preview
		puts "Clearing preview directory #{@cfg.directories.preview} ..." if $DEBUG
		`rm -fr #{@cfg.directories.preview}/*`
		raise TanitException, "Command failed" unless $?.success?

		if not Dir["#{@cfg.directories.static}/*"].empty?
			puts "Copying static files from #{@cfg.directories.static} ..." if $DEBUG
			`cp -a #{@cfg.directories.static}/* #{@cfg.directories.preview}/`
			raise TanitException, "Command failed" unless $?.success?
		end
	end

	# Copy the preview content to the production dir
	def publish
		# Check if preview is empty
		if Dir["#{@cfg.directories.preview}/*"].empty?
			puts "Preview directory is empty, nothing to publish."
			exit 3
		end

		puts "Clearing production directory #{@cfg.directories.production} ..." if $DEBUG
		`rm -fr #{@cfg.directories.production}/*`
		raise TanitException, "Command failed" unless $?.success?

		puts "Publishing preview in #{@cfg.directories.production} ..." if $DEBUG
		`cp -a #{@cfg.directories.preview}/* #{@cfg.directories.production}/`
		raise TanitException, "Command failed" unless $?.success?
		
	end

	protected
		def load()
			# Load all posts
			Dir.glob(File.join(@cfg.directories.posts, "*.md")).each{ |f|
				begin
					@posts<<Post.new(f)
				rescue TanitException => e
					puts "Syntax error in #{f}: #{e.message}"
				rescue Exception => e
					puts "Error reading file #{f}: #{e.message}"
				end
			}

			# Order posts by date (do not use Comparable in class Post as == operator will be wrong
			@posts.sort! { |a,b| a.date <=> b.date }

			# Create tags index
			@posts.each { |post|
				post.tags.each { |tag|
					(@tags[tag] ||=[]).push(post)
				}
			}
			
			# Create years index
			@posts.each { |post|
				(@years[post.date.year] ||=[]).push(post)
			}

			# Load the templates
			@cfg.templates.to_h.each { |object,file|
				@templates[object]= Slim::Template.new(
					File.join(@cfg.directories.templates, file),
					:pretty => @cfg.pretty_html || $DEBUG
				)
			}
		end
end


class Main
	VERSION = '1.0.0'
	
	attr_reader :options

	def initialize()
		# Set defaults
		@options = OpenStruct.new
		@options.config_file = "/etc/tanitblog/tanitblog.conf"

		# Parse options, check arguments, then process the command
		parse_options
		process_arguments						 

		begin
			process_command
		rescue TanitException => e
			puts "Error: #{e.message}"
			puts e.backtrace.join("\n") if $DEBUG
			exit 1
		end
	end
	
	protected
	
		def parse_options
			
			# Specify options
			opts = OptionParser.new 
			opts.banner="Usage: #{$0} [options]"

			opts.on_tail('-V', '--version')		{ print_version ; exit 0 }
			opts.on_tail('-h', '--help')		{ puts opts ; exit 0 }
			opts.on_tail('-d', '--debug')		{ $DEBUG = true }

			opts.on('-g', '--generate', 'Generate blog for preview') 	{ @options.generate = true }
			opts.on('-l', '--list', 'List all posts')					{ @options.list = true }
			opts.on('-p', '--publish', 'Publish the preview version')	{ @options.publish = true }
			opts.on('-s uuid', '--show uuid', "Show specified post") { |uuid| 
				@options.show = uuid 
			}
			opts.on('-c file', '--config file', "Specify configuration file") {|file| 
				@options.config_file = file 
			}

			begin
				opts.parse!
				check_arguments
			rescue Exception
				# Display help in case of error
				puts opts
				exit 3
			end
		end
		
		def print_version
			puts "#{File.basename(__FILE__)} version #{VERSION}"
		end
		
		def check_arguments
			if not (@options.generate or @options.list or @options.publish or @options.show)
				puts "At least one action required."
				raise TanitException
			end
		end

		# Setup the arguments
		def process_arguments
			if @options.publish
				print "Are you sure you want to publish ? [yN]: "
				if gets.chomp.downcase != "y"
					puts "Aborded by user."
					exit(0)
				end
			end

			# Check configuration file
			if not File.file?(@options.config_file)
				puts "Configuration file not found: #{@options.config_file}"
				exit 3
			end
		end
		
		# Main function
		def process_command
			blog=Blog.new(@options.config_file)

			# List all blog entries	
			if @options.list
				puts " UUID                            | Filename"
				puts "==========================================="
				blog.posts.each{ |post|
					puts "#{post.uuid} | #{post.urlname}"
				}
			end

			# Display specified post
			if @options.show
				uuid=@options.show

				post=blog[uuid]
				if post.nil?
					puts "Post not found."
				else
					puts "Filename: #{post.urlname}"
					puts "Content:"
					if $DEBUG
						puts post
					else
						puts blog.generate_post(post)
					end
				end
			end

			# Generate outout in preview directory
			if @options.generate
				blog.clear_preview
				blog.write_index
				blog.write_all_posts
				puts "Generated #{blog.posts.count} posts."
			end

			# Publish current preview content
			if @options.publish
				blog.publish
				puts "Preview content published."
			end

		end
end

# Start the application
Main.new

# vim: ts=4:sw=4:ai:noet
