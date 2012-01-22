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
  end
end