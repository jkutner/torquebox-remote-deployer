TorqueBox::RemoteDeploy.configure do
  torquebox_home "#{File.expand_path("tmp/torquebox", File.dirname(__FILE__))}"
  hostname "localhost"
  local true
end