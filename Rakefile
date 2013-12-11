task :deploy do
  IO.popen "ssh root@charlie.bz", "w" do |io|
    io.puts <<-SH
      export RACK_ENV=production
      cd /var/www/charlie.bz
      git fetch
      git reset --hard origin/master
      /opt/rubies/ruby-2.0.0-p0/bin/bundle install --deployment | grep -v '^Using'
      touch tmp/restart.txt
      exit
    SH
  end
end
