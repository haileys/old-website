task :deploy do
  IO.popen "ssh root@hailey.lol", "w" do |io|
    io.puts <<-SH
      export RACK_ENV=production
      cd /var/www/hailey.lol
      git pull origin master
      /usr/local/rvm/wrappers/ruby-1.9.3-p194/bundle install --deployment | grep -v '^Using'
      touch tmp/restart.txt
      exit
    SH
  end
end