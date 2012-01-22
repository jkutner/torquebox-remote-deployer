TorqueBox::RemoteDeploy.configure do
  host do
    torquebox_home "/my/tb/dir"
    jboss_home "/my/jboss/dir"
    hostname "1.2.3.4"
    port "2222"
    user "torquebox"
    key "~/.ssh/id_rsa.pub"
    sudo true
  end

  host do
    hostname "4.4.4.4"
    port "22"
    user "deploy"
    key "~/.ssh/torquebox.pub"
  end
end