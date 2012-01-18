require "net/ssh"
require "net/scp"

module TorqueBox
  module RemoteDeployUtils
    class << self

      def stage(archive_file)
        with_config(archive_file) do |config, app_name|
          cleanup_stage(config, archive_file, app_name)
          prepare_stage(config, app_name)
          stage_archive(config, archive_file)
          unjar_staged_archive(config, archive_file, app_name)
        end
      end

      def deploy(archive_file)
        with_config(archive_file) do |config, app_name|
          scp_upload(config, archive_file, "#{config.torquebox_home}/jboss/standalone/deployments/")
          do_deploy(config, app_name)
        end
      end

      def deploy_from_stage(archive_file)
        with_config(archive_file) do |config, app_name|
          ssh_exec(config, "cp #{config.torquebox_home}/stage/#{app_name}.knob #{config.torquebox_home}/jboss/standalone/deployments")
          do_deploy(config, app_name)
        end
      end

      def undeploy(archive_file)
        with_config(archive_file) do |config, app_name|
          ssh_exec(config, "rm -f #{config.torquebox_home}/jboss/standalone/deployments/#{app_name}.knob*")
        end
      end

      def exec_ruby(archive_file, cmd)
        with_config(archive_file) do |config, app_name|
          ssh_exec(config, "cd #{config.torquebox_home}/stage/#{app_name}",
                   "export PATH=$PATH:#{config.torquebox_home}/jruby/bin",
                   "#{config.torquebox_home}/jruby/bin/jruby -S #{cmd}")
        end
      end

      private

      def prefix(config)
        config.sudo ? "sudo" : p
      end

      def do_deploy(config, app_name)
        ssh_exec(config, "touch #{config.torquebox_home}/jboss/standalone/deployments/#{app_name}.knob.dodeploy")
      end

      def app_name(archive_file)
        File.basename(archive_file, ".knob")
      end

      def unjar_staged_archive(config, archive_file, app_name)
        ssh_exec(config, "cd #{config.torquebox_home}/stage/#{app_name} && #{prefix(config)}jar -xf ../#{archive_file}")
      end

      def stage_archive(config, archive_file)
        scp_upload(config, archive_file, "#{config.torquebox_home}/stage/#{File.basename(archive_file)}")
      end

      def cleanup_stage(config, archive_file, app_name)
        ssh_exec(config, "rm -f #{config.torquebox_home}/stage/#{archive_file}")
        ssh_exec(config, "rm -rf #{config.torquebox_home}/stage/#{app_name}")
      end

      def prepare_stage(config, app_name)
        ssh_exec(config, "mkdir -p #{config.torquebox_home}/stage/#{app_name}")
      end

      def with_config(archive_file)
        yield read_config, app_name(archive_file)
      end

      def ssh_exec(config, *cmd)
        Net::SSH.start(config.hostname, config.user, :port => config.port, :keys => [config.key]) do |ssh|
          ssh.exec(cmd.map { |c| "#{prefix(config)} #{c}" }.join("\n"))
        end
      end

      def scp_upload(config, local_file, remote_file)
        Net::SCP.upload!(config.hostname, config.user, local_file, remote_file,
                         :ssh => {:port => config.port, :keys => [config.key]}
        ) do |ch, name, sent, total|
          print "\rCopying #{name}: #{sent}/#{total}"
        end
        print "\n"
      end

      def read_config
        eval(File.read("config/torquebox_remote.rb")).config
      end
    end
  end

  class RemoteDeploy
    def self.configure(&blk)
      new(blk)
    end

    def initialize(blk)
      @config = RemoteConfig.new
      instance_eval &blk
    end

    attr_reader :config

    def hostname(h)
      @config.hostname = h
    end

    def port(p)
      @config.port = p
    end

    def user(u)
      @config.user = u
    end

    def key(k)
      @config.key = k
    end

    def torquebox_home(tbh)
      @config.torquebox_home = tbh
    end

    def sudo(sudo)
      @config.sudo = sudo
    end
  end

  class RemoteConfig
    attr_accessor :hostname, :port, :user, :key, :torquebox_home, :sudo

    def initialize
      @user = "torquebox"
      @torquebox_home = "/opt/torquebox"
      @sudo = false
    end
  end
end