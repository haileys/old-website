require "bundler/setup"
Bundler.require :default

Dir["./models/*.rb"].each &method(:require)

CONFIG = YAML.load_file "config.yml"
ActiveRecord::Base.establish_connection CONFIG["db"]

set :erb, escape_html: true

helpers do
  include ActionView::Helpers::DateHelper
  
  def post_path(post)
    "/blog/#{post.id}"
  end
end

before do
  if Sinatra::Application.environment == :development
    # reload config
    Object.send :remove_const, :CONFIG
    CONFIG = YAML.load_file "config.yml"
  end
end

get "/" do
  erb :index
end

get "/blog" do
  @posts = Post.recent
  erb :blog
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