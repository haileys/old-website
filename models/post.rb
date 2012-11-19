# coding: utf-8

class Post
  class NotFound < StandardError; end
  
  attr_accessor :slug, :title, :content, :created_at
  
  def initialize(opts = {})
    opts.each do |k,v|
      send "#{k}=", v
    end
  end
  
  def self.find_all_posts
    CONFIG["posts"].map { |s| s.strip.split(/\s+/) }.map do |slug, date|
      filename = "posts/#{slug}.md"
      content = File.read filename
      created_at = date || Time.now.to_s
      next unless content =~ /\A# (.*)$/
      Post.new slug: slug, title: $1, content: $'.strip, created_at: created_at
    end.compact
  end
  
  def self.all
    @@all ||= Hash[find_all_posts.map { |p| [p.slug, p] }]
  end
  
  def self.clear_cache!
    @@all = nil
  end
  
  def self.recent(n = 5)
    all.to_a.reverse.last(n).map { |k,v| v }
  end
  
  def self.latest
    recent(1).first
  end
  
  def self.find(slug)
    all[slug] or raise NotFound
  end
end
