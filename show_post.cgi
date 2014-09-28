#!/opt/rubies/2.1.2/bin/ruby
require "bundler/setup"
require "cgi"
cgi = CGI.new

all_posts = Dir.entries("#{__dir__}/posts")

unless slug = cgi["slug"] and all_posts.include?("#{slug}.md")
  puts <<-HTML
Status: 404
Content-Type: text/html

<h1>Not found</h1>
HTML
end

require "pygments.rb"
require "rdiscount"

post_path = "#{__dir__}/posts/#{slug}.md"

markdown = File.read(post_path).gsub(/^    \\[a-z]+\s*\n(    .*(\n|$)|\s*(\n|$))*/) { |snippet|
  lang, *source = snippet.lines.to_a
  Pygments.highlight source.map { |x| x[4..-1] }.join, lexer: lang[5..-1].strip, options: { encoding: "utf-8" }
}

/\A# (?<post_title>.*)$/ =~ markdown

post_date = `git log --format='%ai' #{post_path} | tail -1`.split.first

html = RDiscount.new(markdown).to_html

puts <<-HTML
Status: 200
Content-Type: text/html

<!DOCTYPE html>
<html>
<head>
  <title>#{post_title}</title>
  <style>#{Pygments.css}</style>
  <style>
    body {
      font-family:Georgia, serif;
    }
    .container {
      margin:32px;
      width:800px;
    }
    nav {
      border-bottom:1px solid #cccccc;
      padding-bottom:16px;
    }
    .date {
      float:right;
    }
    pre {
      padding:8px;
      background-color:#f3f3f3;
      font-family:Monaco, Consolas, "Courier New", monospace;
      font-size:12px;
      line-height:16px;
    }
  </style>
</head>
<body>
  <div class="container">
    <nav>
      <a href="/">&laquo; Home</a>
      <span class="date">#{post_date}</span>
    </nav>
    <div class="post">
      #{html}
    </div>
  </div>
</body>
</html>
HTML
