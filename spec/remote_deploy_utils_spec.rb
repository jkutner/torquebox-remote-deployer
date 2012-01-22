require 'spec_helper'

describe TorqueBox::RemoteDeployUtils do

  before(:each) do
    @util = TorqueBox::RemoteDeployUtils
  end

  describe ".stage" do
    it "stages one host" do
      ENV["config_file"] = File.join(File.dirname(__FILE__), "fixtures/simple_torquebox_remote.rb")
      @util.stub(:ssh_exec)
      @util.should_receive(:scp_upload).with(anything(), "myapp.knob", "/opt/torquebox/stage/myapp.knob")
      @util.stage("myapp.knob")
    end

    it "stages two hosts" do
      ENV["config_file"] = File.join(File.dirname(__FILE__), "fixtures/multihost_torquebox_remote.rb")
      @util.stub(:ssh_exec)
      @util.should_receive(:scp_upload).with(anything(), "myapp.knob", "/my/tb/dir/stage/myapp.knob")
      @util.should_receive(:scp_upload).with(anything(), "myapp.knob", "/opt/torquebox/stage/myapp.knob")
      @util.stage("myapp.knob")
    end

    context "local" do
      it "stages" do
        ENV["config_file"] = File.join(File.dirname(__FILE__), "fixtures/local_torquebox_remote.rb")
        @util.stage("myapp.knob")  # does nothing
      end
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
        ENV["config_file"] = File.join(File.dirname(__FILE__), "fixtures/local_torquebox_remote.rb")
        @util.deploy(File.join(File.dirname(__FILE__), "fixtures/myapp.knob"))
        File.exists?("#{deploy_dir}/myapp.knob").should == true
        File.exists?("#{deploy_dir}/myapp.knob.dodeploy").should == true
      end

      def deploy_dir
        "#{File.dirname(__FILE__)}/../tmp/torquebox/jboss/standalone/deployments/"
      end
    end
  end
end