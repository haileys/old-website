class Post
  class NotFound < StandardError; end
  
  attr_accessor :id, :title, :content, :created_at
  
  def initialize(opts = {})
    opts.each do |k,v|
      send "#{k}=", v
    end
  end
  
  def self.find_all_posts
    Dir["posts/*.md"].map do |filename|
      filename =~ %r{/(\d+)\.}
      id = $1.to_i
      content = File.read filename
      created_at = rbs.git("log", { format: "%aD" }, filename).lines.to_a.last.strip
      next unless content =~ /\A# (.*)$/
      Post.new id: id, title: $1, content: $'.strip, created_at: created_at
    end.compact
  end
  
  def self.all
    @@all ||= Hash[find_all_posts.map { |p| [p.id, p] }]
  end
  
  def self.clear_cache!
    @@all = nil
  end
  
  def self.recent(n = 5)
    @@recent ||= all.sort { |(a,_),(b,_)| b <=> a }.map { |_,p| p }
    if n == :all
      @@recent
    else
      @@recent.take n
    end
  end
  
  def self.latest
    recent(:all).first
  end
  
  def self.find(id)
    all[id.to_i] or raise NotFound
  end
end