task :deploy do
  IO.popen "ssh root@charlie.bz", "w" do |io|
    io.puts <<-SH
      export RACK_ENV=production
      cd /var/www/charlie.bz
      git pull origin master
      /usr/local/rvm/wrappers/ruby-1.9.3-p194/bundle install | grep -v '^Using'
      touch tmp/restart.txt
      exit
    SH
  end
end