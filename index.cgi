#!/opt/rubies/ruby-2.1.2/bin/ruby

print "Content-Type: text/html\r\n\r\n"

puts <<-"HTML"
<TITLE>Charlie Somerville</TITLE>
<H1>Charlie's Home Page</H1>
<P>
  Welcome to Charlie's Home Page on the World Wide Web.
<P>
  <IMG SRC=CONSTR~1.GIF WIDTH=38 HEIGHT=38>
<P>
  <A HREF=mailto:charlie@charliesomerville.com>E-Mail</A>
<HR>
<P>
  <I>Last Updated: #{`git log --format='%aD' -1 #{__FILE__}`}</I>
HTML
