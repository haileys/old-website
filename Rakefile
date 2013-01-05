task :deploy do
  IO.popen "ssh root@charlie.bz", "w" do |io|
    io.puts <<-SH
      export RACK_ENV=production
      cd /var/www/charlie.bz
      git pull origin master
      /usr/local/rvm/wrappers/ruby-2.0.0-preview2/bundle install --deployment | grep -v '^Using'
      touch tmp/restart.txt
      exit
    SH
  end
end
