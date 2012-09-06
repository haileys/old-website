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
    markdown source.gsub(/^```[a-z]+\s*\n(.|\n)*?^```/) { |snippet|
      lang, *source, _ = snippet.lines.to_a
      Pygments.highlight source.join("\n"), lexer: lang[3..-1].strip, options: { encoding: "utf-8" }
    }
  end
end

before do
  if Sinatra::Application.environment == :development
    # reload config
    Object.send :remove_const, :CONFIG
    CONFIG = YAML.load_file "config.yml"
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
  erb :blog
end

get "/blog/all" do
  @posts = Post.recent :all
  erb :blog_all
end

get "/blog/new" do
  only_charlie!
end

get "/blog/:id.md" do
  post = Post.find params[:id]
  content_type "text/plain"
  "# #{post.title}\n\n#{post.content}"
end

get "/blog/:id" do
  @post = Post.find params[:id]
  erb :blog_post
end

get "/code" do
  erb :code
end

get "/talks" do
  erb :talks
end

get "/resume" do
  erb :resume
end

get "/style.css" do
  scss :style
end