require 'spec_helper'

describe TorqueBox::RemoteDeploy do
  describe ".configure" do
    context "defaults" do
      subject do
        TorqueBox::RemoteDeploy.configure do
          hostname "1.2.3.4"
          port "2222"
          user "torquebox"
          key "~/.ssh/id_rsa.pub"
        end
      end

      it "has one configurations" do
        subject.configurations.size.should == 1
        subject.config.should == subject.configurations[0]
      end

      it "has hostname 1.2.3.4" do
        subject.config.hostname.should == "1.2.3.4"
      end

      it "has port 2222" do
        subject.config.port.should == "2222"
      end

      it "has user torquebox" do
        subject.config.user.should == "torquebox"
      end

      it "has key '~/.ssh/id_rsa.pub'" do
        subject.config.key.should == "~/.ssh/id_rsa.pub"
      end

      it "has torquebox_home '/opt/torquebox'" do
        subject.config.torquebox_home.should == "/opt/torquebox"
      end

      it "has jboss_home '/opt/torquebox/jboss'" do
        subject.config.jboss_home.should == "/opt/torquebox/jboss"
      end

      it "has sudo false" do
        subject.config.sudo.should == false
      end

      it "has jruby_home of '/opt/torquebox/jruby'" do
        subject.config.jruby_home.should == '/opt/torquebox/jruby'
      end
    end

    context "overrides" do
      subject do
        TorqueBox::RemoteDeploy.configure do
          torquebox_home "/my/tb/dir"
          jboss_home "/my/jboss/dir"
          jruby_home "/opt/jruby"
          hostname "1.2.3.4"
          port "2222"
          user "torquebox"
          key "~/.ssh/id_rsa.pub"
          sudo true
        end
      end

      it "has one configurations" do
        subject.configurations.size.should == 1
        subject.config.should == subject.configurations[0]
      end

      it "has hostname 1.2.3.4" do
        subject.config.hostname.should == "1.2.3.4"
      end

      it "has port 2222" do
        subject.config.port.should == "2222"
      end

      it "has user torquebox" do
        subject.config.user.should == "torquebox"
      end

      it "has key '~/.ssh/id_rsa.pub'" do
        subject.config.key.should == "~/.ssh/id_rsa.pub"
      end

      it "has torquebox_home '/my/tb/dir'" do
        subject.config.torquebox_home.should == "/my/tb/dir"
      end

      it "has jboss_home '/my/jboss/dir'" do
        subject.config.jboss_home.should == "/my/jboss/dir"
      end

      it "has sudo true" do
        subject.config.sudo.should == true
      end

      it "has jruby_home of '/opt/jruby'" do
        subject.config.jruby_home.should == "/opt/jruby"
      end
    end

    context "multiple hosts" do
      subject do
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
      end

      it "has one configurations" do
        subject.configurations.size.should == 2
      end

      it "has correct config" do
        test_config(subject.configurations[0])
        test_config(subject.configurations[1])
      end

      def test_config(configuration)
        if configuration.hostname == "4.4.4.4"
          configuration.torquebox_home.should == "/opt/torquebox"
        elsif configuration.hostname == "1.2.3.4"
          configuration.torquebox_home.should == "/my/tb/dir"
        else
          fail
        end
      end
    end
  end
end