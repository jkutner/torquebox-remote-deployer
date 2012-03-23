require "net/ssh"
require "net/scp"

require 'tempfile'

module TorqueBox
  module RemoteDeployUtils
    class << self

      def stage(archive_file)
        with_config(archive_file) do |config, app_name|
          # no need to stage if we are local. we'll just run from the app dir
          unless config.local
            cleanup_stage(config, archive_file, app_name)
            prepare_stage(config, app_name)
            stage_archive(config, archive_file)
            unjar_staged_archive(config, archive_file, app_name)
          end
        end
      end

      def deploy(archive_file)
        with_config(archive_file) do |config, app_name|
          scp_upload(config, archive_file, "#{config.jboss_home}/standalone/deployments/")
          do_deploy(config, app_name)
        end
      end

      def deploy_from_stage(archive_file)
        with_config(archive_file) do |config, app_name|
          unless config.local
            ssh_exec(config, "cp #{config.torquebox_home}/stage/#{app_name}.knob #{config.jboss_home}/standalone/deployments")
          else
            scp_upload(config, archive_file, "#{config.jboss_home}/standalone/deployments/")
          end
          do_deploy(config, app_name)
        end
      end

      def undeploy(archive_file)
        with_config(archive_file) do |config, app_name|
          unless config.local
            ssh_exec(config, "rm -f #{config.jboss_home}/standalone/deployments/#{app_name}-knob.yml*")
            ssh_exec(config, "rm -f #{config.jboss_home}/standalone/deployments/#{app_name}.knob")
          else
            FileUtils.rm("#{config.jboss_home}/standalone/deployments/#{app_name}-knob.yml*")
            FileUtils.rm("#{config.jboss_home}/standalone/deployments/#{app_name}.knob")
          end
        end
      end

      def exec_ruby(archive_file, cmd)
        with_config(archive_file) do |config, app_name|
          unless config.local
            ssh_exec(config, "cd #{config.torquebox_home}/stage/#{app_name}",
                     "export PATH=$PATH:#{config.torquebox_home}/jruby/bin",
                     "export RAILS_ENV=production",
                     "#{config.torquebox_home}/jruby/bin/jruby -S #{cmd}")
          else
            # not sure what to do here yet
          end
        end
      end

      private

      def prefix(config)
        config.sudo ? "sudo" : p
      end

      def do_deploy(config, app_name)
        # TODO create a -knob.yml that points to knob file
        # TODO set RAILS_ENV based on env var, and default to production
        knob_yml = <<-YAML
          application:
            root: #{config.jboss_home}/standalone/deployments/#{app_name}-knob.yml
          environment:
            RAILS_ENV: production
        YAML

        unless config.local
          knob_yml_file = Tempfile.new("#{app_name}-knob.yml")
          knob_yml_file.write(knob_yml)
          scp_upload(config, knob_yml_file.path, "#{config.jboss_home}/standalone/deployments/#{app_name}-knob.yml")
          ssh_exec(config, "touch #{config.jboss_home}/standalone/deployments/#{app_name}-knob.yml.dodeploy")
        else
          # todo copy temp file to somewhere
          File.open("#{config.jboss_home}/standalone/deployments/#{app_name}-knob.yml.dodeploy", "w") {}
        end
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
        unless config.local
          ssh_exec(config, "mkdir -p #{config.torquebox_home}/stage/#{app_name}")
        else
          FileUtils.mkdir_p("#{config.torquebox_home}/stage/#{app_name}")
        end
      end

      def with_config(archive_file)
        read_config.each do |config|
          yield config, app_name(archive_file)
        end
      end

      def ssh_exec(config, *cmd)
        Net::SSH.start(config.hostname, config.user, :port => config.port, :keys => [config.key]) do |ssh|
          ssh.exec(cmd.map { |c| "#{prefix(config)} #{c}" }.join("\n"))
        end
      end

      def scp_upload(config, local_file, remote_file)
        unless config.local
          Net::SCP.upload!(config.hostname, config.user, local_file, remote_file,
                           :ssh => {:port => config.port, :keys => [config.key]}
          ) do |ch, name, sent, total|
            print "\rCopying #{name}: #{sent}/#{total}"
          end
          print "\n"
        else
          FileUtils.cp(local_file, remote_file)
        end
      end

      def read_config
        config_file = ENV["CONFIG_FILE"] || ENV["config_file"] || "config/torquebox_remote.rb"
        eval(File.read(config_file)).configurations
      end
    end
  end

  class RemoteDeploy
    def self.configure(&blk)
      new(blk)
    end

    def initialize(blk)
      @config = RemoteConfig.new
      @configs = []
      instance_eval &blk
    end

    attr_reader :config

    def configurations
      # evenually, we should merge the base @config settings into the @configs
      @configs.empty? ? [@config] : @configs
    end

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

    def jboss_home(jbh)
      @config.jboss_home = jbh
    end

    def sudo(sudo)
      @config.sudo = sudo
    end

    def local(l)
      @config.local = l
    end

    def host(&block)
      @configs << RemoteDeploy.new(block).config
    end
  end

  class RemoteConfig
    attr_accessor :hostname, :port, :user, :key, :torquebox_home, :sudo, :local

    def jboss_home=(jbh)
      @jboss_home = jbh
    end

    def jboss_home
      @jboss_home || "#{@torquebox_home}/jboss"
    end

    def initialize
      @user = "torquebox"
      @torquebox_home = "/opt/torquebox"
      @sudo = false
      @local = false
    end
  end
end