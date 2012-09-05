require "bundler/setup"
Bundler.require :default

Dir["./models/*.rb"].each &method(:require)

config = YAML.load_file("config.yml")[Sinatra::Application.environment.to_s]
ActiveRecord::Base.establish_connection config["db"]

set :erb, escape_html: true

helpers do
  include ActionView::Helpers::DateHelper
  
  def post_path(post)
    "/blog/#{post.id}"
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

get "/contact" do
  erb :contact
end

get "/style.css" do
  scss :style
end