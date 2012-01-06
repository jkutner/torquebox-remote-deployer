# it would be cool if we could define these in the torquebox.(rb/yml)
# i'll add that if it's approved of
TB_REMOTE_HOME = "/home/vagrant/opt/torquebox"
TB_REMOTE_HOST = "localhost"
TB_REMOTE_PORT = "2222"
TB_REMOTE_USER = "vagrant"
TB_REMOTE_SSH_KEY = "#{ENV["GEM_HOME"]}/gems/vagrant-0.8.7/keys/vagrant"

require "net/ssh"
require "net/scp"
require 'torquebox/deploy_utils'

namespace :torquebox do
  namespace :remote do
    task :stage do
      # need to make this overrideable
      archive_name = TorqueBox::DeployUtils.archive_name
      TorqueBox::RemoteUtils.stage(TB_REMOTE_HOME, archive_name)
    end

    task :exec, [:cmd] do |t, args|
      cmd = args[:cmd] #"bundle install --path vendor/bundle"
      archive_name = TorqueBox::DeployUtils.archive_name
      TorqueBox::RemoteUtils.exec_ruby(TB_REMOTE_HOME, archive_name, cmd)
    end

    task :deploy do
      # cp the local knob to the server's torquebox_home dir
    end

    task :undeploy do
      # ssh_exec remove knob
    end

    def with_ssh_config
      yield TB_REMOTE_HOST, TB_REMOTE_PORT, TB_REMOTE_USER, TB_REMOTE_SSH_KEY
    end

    def with_ssh
      with_ssh_config do |host, port, user, ssh_key|
        Net::SSH.start(host, user, :port => port, :keys => [ssh_key]) do |ssh|
          yield ssh
        end
      end
    end

    def scp_upload(local_file, remote_file)
      with_ssh_config do |host, port, user, ssh_key|
        Net::SCP.upload!(host, user, local_file, remote_file,
                         :ssh => {:port => port, :keys => [ssh_key]}
        ) do |ch, name, sent, total|
          print "\rCopying #{name}: #{sent}/#{total}"
        end
        print "\n"
      end
    end
  end
end

module TorqueBox
  module RemoteUtils
    class << self

      def stage(tb_home, archive_name)
        app_name = app_name(archive_name)
        cleanup_stage(tb_home, archive_name, app_name)
        prepare_stage(tb_home, app_name)
        stage_archive(tb_home, archive_name)
        unjar_staged_archive(tb_home, archive_name, app_name)
      end

      def undeploy(tb_home, archive_name)
        app_name = app_name(archive_name)
      end

      def exec_ruby(tb_home, archive_name, cmd)
        app_name = app_name(archive_name)
        with_ssh do |ssh|
          ssh.exec("cd #{tb_home}/stage/#{app_name}
                    #{tb_home}/jruby/bin/jruby -S #{cmd}")
        end
      end

      private

      def app_name(archive_name)
        archive_name.gsub(/.knob/, "")
      end

      def unjar_staged_archive(tb_home, archive_name, app_name)
        with_ssh do |ssh|
          ssh.exec("cd #{tb_home}/stage/#{app_name}
                    jar -xf ../#{archive_name}")
        end
      end

      def stage_archive(tb_home, archive_name)
        scp_upload("#{archive_name}", "#{tb_home}/stage/")
      end

      def cleanup_stage(tb_home, archive_name, app_name)
        with_ssh do |ssh|
          ssh.exec!("rm #{tb_home}/stage/#{archive_name}")
          ssh.exec!("rm -rf #{tb_home}/stage/#{app_name}")
        end
      end

      def prepare_stage(tb_home, app_name)
        with_ssh do |ssh|
          ssh.exec!("mkdir -p #{tb_home}/stage/#{app_name}")
        end
      end

      def with_ssh_config
        yield TB_REMOTE_HOST, TB_REMOTE_PORT, TB_REMOTE_USER, TB_REMOTE_SSH_KEY
      end

      def with_ssh
        with_ssh_config do |host, port, user, ssh_key|
          Net::SSH.start(host, user, :port => port, :keys => [ssh_key]) do |ssh|
            yield ssh
          end
        end
      end

      def scp_upload(local_file, remote_file)
        with_ssh_config do |host, port, user, ssh_key|
          Net::SCP.upload!(host, user, local_file, remote_file,
                           :ssh => {:port => port, :keys => [ssh_key]}
          ) do |ch, name, sent, total|
            print "\rCopying #{name}: #{sent}/#{total}"
          end
          print "\n"
        end
      end
    end
  end
end