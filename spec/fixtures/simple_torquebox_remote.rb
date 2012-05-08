TorqueBox::RemoteDeploy.configure do
  torquebox_home "/opt/torquebox"
  hostname "localhost"
  port "2222"
  user "torquebox"
  key "~/.ssh/id_rsa.pub"
  rails_env "production"
  rack_env "production"
end