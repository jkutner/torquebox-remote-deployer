require 'rake'
require 'torquebox/deploy_utils'
require 'torquebox/remote_deploy_utils'

namespace :torquebox do
  namespace :remote do
    task :stage do
      # need to make this overridable in the 
      archive_name = TorqueBox::DeployUtils.archive_name
      TorqueBox::RemoteDeployUtils.stage(archive_name)
    end

    task :exec, [:cmd] do |t, args|
      cmd = args[:cmd]
      archive_name = TorqueBox::DeployUtils.archive_name
      TorqueBox::RemoteDeployUtils.exec_ruby(archive_name, cmd)
    end

    task :deploy do
      # cp the local knob to the server's torquebox_home dir
    end

    task :undeploy do
      # ssh_exec remove knob
    end
  end
end
