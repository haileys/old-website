# coding: utf-8

require "bundler/setup"
Bundler.require :default

RubyPython.configure python_exe: "/usr/bin/python2.7" if production?

Dir["./models/*.rb"].each &method(:require)

CONFIG = YAML.load_file "config.yml"
COMMIT_ID = File.read(".git/refs/heads/master").strip

set :erb, escape_html: true

helpers do
  include ActionView::Helpers::DateHelper
  
  def post_path(post)
    "/blog/#{post.id}-#{post.title.parameterize}"
  end
  
  def format_post(source)
    markdown source.gsub(/^    \\[a-z]+\s*\n(    .*\n)*/) { |snippet|
      lang, *source = snippet.lines.to_a
      Pygments.highlight source.map { |x| x[4..-1] }.join("\n"), lexer: lang[5..-1].strip, options: { encoding: "utf-8" }
    }
  end
  
  def abbreviated_post(source)
    format_post source.split("\n\n").take(3).join("\n\n")
  end
end

before do
  if development?
    # reload config
    Object.send :remove_const, :CONFIG
    CONFIG = YAML.load_file "config.yml"
    # reload post cache
    Post.clear_cache!
  end
end

error Post::NotFound do
  redirect "/"
end

get "/" do
  @latest_post = Post.latest
  erb :index
end

get "/blog" do
  @posts = Post.recent
  @title = "Blog"
  erb :blog
end

get "/blog.rss" do
  @posts = Post.recent
  content_type "application/rss+xml"
  erb :blog_rss, layout: false
end

get "/blog/all" do
  @posts = Post.recent :all
  @title = "All posts"
  erb :blog_all
end

get "/blog/:id.md" do
  post = Post.find params[:id]
  content_type "text/plain"
  "# #{post.title}\n\n#{post.content}"
end

get "/blog/:id" do
  @post = Post.find params[:id]
  @title = @post.title
  erb :blog_post
end

get "/code" do
  @title = "Code"
  erb :code
end

get "/talks" do
  @title = "Talks"
  erb :talks
end

get "/resume" do
  @title = "Résumé"
  erb :resume
end

get "/style.css" do
  scss :style
end