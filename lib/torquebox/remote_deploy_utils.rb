# it would be cool if we could define these in the torquebox.(rb/yml)
# i'll add that if it's approved of
TB_REMOTE_HOME = "/home/vagrant/opt/torquebox"
TB_REMOTE_HOST = "localhost"
TB_REMOTE_PORT = "2222"
TB_REMOTE_USER = "vagrant"
TB_REMOTE_SSH_KEY = "#{ENV["GEM_HOME"]}/gems/vagrant-0.8.7/keys/vagrant"

require "net/ssh"
require "net/scp"

module TorqueBox
  module RemoteDeployUtils
    class << self

      def stage(archive_file)
        with_server_config(archive_file) do |tb_home, app_name|
          cleanup_stage(tb_home, archive_file, app_name)
          prepare_stage(tb_home, app_name)
          stage_archive(tb_home, archive_file)
          unjar_staged_archive(tb_home, archive_file, app_name)
        end
      end

      def deploy(archive_file)
        with_server_config(archive_file) do |tb_home|
          ssh_exec("mkdir -p #{tb_home}/apps")
          scp_upload("#{archive_file}", "#{tb_home}/apps/")
        end
      end

      def undeploy(archive_file)
        with_server_config(archive_file) do |tb_home|
          ssh_exec("rm #{tb_home}/apps/#{archive_file}")
        end
      end

      def exec_ruby(archive_file, cmd)
        with_server_config(archive_file) do |tb_home, app_name|
          ssh_exec("cd #{tb_home}/stage/#{app_name} && #{tb_home}/jruby/bin/jruby -S #{cmd}")
        end
      end

      private

      def app_name(archive_file)
        File.basename(archive_file)
      end

      def unjar_staged_archive(tb_home, archive_file, app_name)
        ssh_exec("cd #{tb_home}/stage/#{app_name} && jar -xf ../#{archive_file}")
      end

      def stage_archive(tb_home, archive_file)
        scp_upload("#{archive_file}", "#{tb_home}/stage/")
      end

      def cleanup_stage(tb_home, archive_file, app_name)
        with_ssh do |ssh|
          ssh.exec!("rm #{tb_home}/stage/#{archive_file}")
          ssh.exec!("rm -rf #{tb_home}/stage/#{app_name}")
        end
      end

      def prepare_stage(tb_home, app_name)
        ssh_exec("mkdir -p #{tb_home}/stage/#{app_name}")
      end

      def with_server_config(archive_file)
        yield TB_REMOTE_HOME, app_name(archive_file)
      end

      def with_ssh_config
        yield TB_REMOTE_HOST, TB_REMOTE_PORT, TB_REMOTE_USER, TB_REMOTE_SSH_KEY
      end

      def with_ssh
        with_ssh_config do |host, port, user, ssh_key, tb_home|
          Net::SSH.start(host, user, :port => port, :keys => [ssh_key]) do |ssh|
            yield ssh
          end
        end
      end

      def ssh_exec(cmd)
        with_ssh do |ssh|
          ssh.exec(cmd)
        end
      end

      def scp_upload(local_file, remote_file)
        with_ssh_config do |host, port, user, ssh_key, tb_home|
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