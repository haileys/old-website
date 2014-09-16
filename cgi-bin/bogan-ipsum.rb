#!/opt/rubies/ruby-2.1.2/bin/ruby
require "open-uri"
require "nokogiri"

print "Content-Type: text/html\n\n"

doc = Nokogiri::XML(open("http://boganipsum.com/").read)

sentences = doc.css(".bogan-ipsum p").flat_map { |p| p.text.split(/(?<=\. )/) }

print sentences.sample.gsub(/\s+/, " ").strip
