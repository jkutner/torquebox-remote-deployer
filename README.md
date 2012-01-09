# torquebox-remote-deployer

The torquebox-remote-deployer is a Ruby Gem for deploying TorqueBox `.knob` files to a remote TorqueBox server.  It
allows you to deploy your entire application as a single file, but still be able to run Rake and other jobs on the
server.

## How to Use It

First, you'll need to set up your TorqueBox application for Rake.
Then run `gem install torquebox-remote-deployer` or add the gem to your `Gemfile`:

    gem "torquebox-remote-deployer"

Once the Gem is installed, you'll have a few new Rake tasks:

    rake torquebox:remote:deploy         # Deploy the archive file to the remot...
    rake torquebox:remote:exec[cmd]      # Execute Ruby commands against the re...
    rake torquebox:remote:stage          # Upload the archive file to the remot...
    rake torquebox:remote:undeploy       # Undeploy the archive file to the rem...

Before using these, you'll need to configure your remote server by creating a `config/torquebox_remote.rb` file in your project.
This file will be similar to `config/torquebox.rb` in its format, but the directives are different.
You'll need to configure it like this:

    TorqueBox::RemoteDeploy.configure do
      torquebox_home "/opt/torquebox"
      hostname "localhost"
      port "2222"
      user "vagrant"
      key "#{ENV["GEM_HOME"]}/gems/vagrant-0.8.7/keys/vagrant"
      sudo true
    end

Of course, fill in the values with your own server information.
Then you can stage your application on the remote server with this command:

    $ rake torquebox:remote:stage

This will create a Knob file, copy it to the remote server, and explode it to a location where commands can be run from
its root directory; like this:

    $ rake torquebox:remote:exec["bundle install --path vendor/bundle"]

Now you can to do more useful things like running migrations:

    $ rake torquebox:remote:exec["rake db:migrate RAILS_ENV=production"]

After the `exec` tasks are complete, you can deploy the Knob to the TorqueBox server.

    $ rake torquebox:remote:deploy

This task works just like the `torquebox:deploy:archive` task, but remotely.

## TODO

*  Make it friendly to remote Windows targets (already works on Windows source machines)