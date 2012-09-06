require "bundler/setup"
Bundler.require :default

Dir["./models/*.rb"].each &method(:require)

CONFIG = YAML.load_file "config.yml"

set :erb, escape_html: true

helpers do
  include ActionView::Helpers::DateHelper
  
  def post_path(post)
    "/blog/#{post.id}-#{post.title.parameterize}"
  end
  
  def only_charlie!
    auth = Rack::Auth::Basic::Request.new request.env
    password = BCrypt::Password.new CONFIG["password"]
    unless auth.provided? and auth.basic? and auth.credentials and auth.credentials.last == password
      response["WWW-Authenticate"] = "Basic realm=\"only charlie\""
      halt 401, "Unauthorized"
    end
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