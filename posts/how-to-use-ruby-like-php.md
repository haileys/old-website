# How to use Ruby like PHP

If you're like me, you often want to stick a script on your web server and have it run. For that, PHP's pretty much your only option... right?

**Nope!**

Here's a little trick I did today that I'd like to share. I'll assume you're running Apache.

Add the following to a `.htaccess` file in your document root:

    \apache
    Options +ExecCGI
    AddHandler cgi-script .erb
    DirectoryIndex index.html index.erb # and whatever else...

Then stick the following script in `/usr/local/bin/erb-cgi`. Make sure to set its execute bit.

    \ruby
    #!/usr/local/rvm/wrappers/ruby-1.9.3-p194/ruby
    
    require "erubis"
    require "cgi"
    
    erb = Erubis::EscapedEruby.new ARGF.readlines.drop(1).join
    
    puts erb.result

If your Ruby is installed somewhere else, feel free to change the shebang line.

Then put this in your document root and call it `time.erb`. Once again, make sure to set it as executable.

    \rhtml
    #!/usr/local/bin/erb-cgi
    <% puts CGI.new.header %>
    
    The time is <b><%= Time.now %></b>

If all goes well, you should see something similar to this: [http://hailey.lol/time.erb](http://hailey.lol/time.erb)

Enjoy!