require 'spec_helper'

describe TorqueBox::RemoteDeployUtils do

  before(:each) do
    @util = TorqueBox::RemoteDeployUtils
  end

  describe ".stage" do
    it "stages one host" do
      ENV["tb_remote_file"] = File.join(File.dirname(__FILE__), "fixtures/simple_torquebox_remote.rb")
      @util.stub(:ssh_exec)
      @util.should_receive(:scp_upload).with(anything(), "myapp.knob", "/opt/torquebox/stage/myapp.knob")
      @util.stage("myapp.knob")
    end

    it "stages two hosts" do
      ENV["tb_remote_file"] = File.join(File.dirname(__FILE__), "fixtures/multihost_torquebox_remote.rb")
      @util.stub(:ssh_exec)
      @util.should_receive(:scp_upload).with(anything(), "myapp.knob", "/my/tb/dir/stage/myapp.knob")
      @util.should_receive(:scp_upload).with(anything(), "myapp.knob", "/opt/torquebox/stage/myapp.knob")
      @util.stage("myapp.knob")
    end

    context "local" do
      it "stages" do
        ENV["tb_remote_file"] = File.join(File.dirname(__FILE__), "fixtures/local_torquebox_remote.rb")
        @util.stage("myapp.knob") # does nothing
      end
    end
  end

  describe "archive name" do
    it "should pick it up from environment variable" do
      ENV["name"] = "archive-file-to-be-deployed"
      @util.archive_name.should == "archive-file-to-be-deployed.knob"
      ENV["name"] = nil
    end

    it "should pick it up torquebox deploy utils if 'name' environment variable is not set" do
      @util.archive_name.should == "#{File.basename(Dir.pwd)}.knob"
    end
  end

  describe ".deploy" do
    context "local" do
      before do
        FileUtils.mkdir_p(deploy_dir)
      end

      after do
        FileUtils.remove_dir("#{File.dirname(__FILE__)}/../tmp/torquebox", true)
      end

      it "deploys" do
        ENV["tb_remote_file"] = File.join(File.dirname(__FILE__), "fixtures/local_torquebox_remote.rb")
        @util.deploy(File.join(File.dirname(__FILE__), "fixtures/myapp.knob"))
        File.exists?("#{deploy_dir}/myapp.knob").should == true

        # this isn't really testing the real deal yet
        File.exists?("#{deploy_dir}/myapp-knob.yml").should == true
        File.exists?("#{deploy_dir}/myapp-knob.yml.dodeploy").should == true
      end

      def deploy_dir
        "#{File.dirname(__FILE__)}/../tmp/torquebox/jboss/standalone/deployments/"
      end
    end
  end
end