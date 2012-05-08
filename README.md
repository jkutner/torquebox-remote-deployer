# torquebox-remote-deployer

The torquebox-remote-deployer is a Ruby Gem for deploying TorqueBox `.knob` files to a remote TorqueBox server.  It
allows you to deploy your entire application as a single file, but still be able to run Rake and other jobs on the
server.

## How to Use It

First, you'll need to set up your TorqueBox application for Rake.
Then run `gem install torquebox-remote-deployer` or add the gem to your `Gemfile`:

    gem "torquebox-remote-deployer"

Once the Gem is installed, you'll have a few new Rake tasks:

    rake torquebox:remote:deploy              # Deploy the local archive file t...
    rake torquebox:remote:exec[cmd]           # Execute Ruby commands against t...
    rake torquebox:remote:stage               # Upload this application to the ...
    rake torquebox:remote:stage:check         # Verify that the archive file ma...
    rake torquebox:remote:stage:deploy        # Deploy the staged archive file ...
    rake torquebox:remote:undeploy            # Undeploy the archive file to th...

Before using these, you'll need to configure your remote server by creating a `config/torquebox_remote.rb` file in your project.
This file will be similar to `config/torquebox.rb` in its format, but the directives are different.
You'll need to configure it like this:

    TorqueBox::RemoteDeploy.configure do
      torquebox_home "/opt/torquebox"
      hostname "localhost"
      port "2222"
      user "vagrant"
      key "~/.vagrant.d/insecure_private_key"
      sudo true
    end

Of course, fill in the values with your own server information.
Then you can stage your application on the remote server with this command:

    $ rake torquebox:remote:stage

This will create a Knob file, copy it to the remote server, and explode it to a location where commands can be run from
its root directory; like this:

    $ rake torquebox:remote:exec["bundle install --path vendor/bundle"]

Or if you ran `bundle --deployment` before creating your Knob you can just jump right in and run something more useful like your migrations:

    $ rake torquebox:remote:exec["bundle exec rake db:migrate"]

After the `exec` tasks are complete, you can deploy the Knob to the TorqueBox server.

    $ rake torquebox:remote:deploy

This task works just like the `torquebox:deploy:archive` task, but remotely.

## Deploying to Multiple Environments

The `torquebox-remote-deployer` gem defaults to production mode, so all the examples shown above will execute with your `production` Bundler group and db config.  But it's most likely that you will want to deploy to a staging or test environment before deploying to production.  In that case, you'll need a config file for each one.  In each config file, you can specify the RACK_ENV or RAILS_ENV like this:

    TorqueBox::RemoteDeploy.configure do
      torquebox_home "/opt/torquebox"
      hostname "localhost"
      port "2222"
      user "vagrant"
      key "~/.vagrant.d/insecure_private_key"

      # set the RAILS_ENV on the remote server
      rails_env "test"
    end

Then you can deploy with the `TB_REMOTE_FILE` environment variable set like this:

    $ TB_REMOTE_FILE=config/torquebox_remote.test.rb rake torquebox:remote:stage

You can name the config file whatever you'd like, and you can have one per environment -- but use the same Rake tasks.

## TODO

*  Make it friendly to remote Windows targets (already works on Windows source machines).
*  Support deploying over FTP or SFTP in addition to SCP/SSH.