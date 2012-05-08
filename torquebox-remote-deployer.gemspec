# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "torquebox-remote-deployer"
  s.version     = "0.1.2.pre1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Joe Kutner"]
  s.email       = ["jpkutner@gmail.com"]
  s.homepage    = "https://github.com/jkutner/torquebox-remote-deployer"
  s.summary     = %q{Deploy Knob files to a remote server with ease.}
  s.description = %q{This utility allows you to deploy a Torquebox Knob file to a remote server}

  s.rubyforge_project = "torquebox-remote-deployer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "jruby-openssl"
  s.add_dependency "net-ssh"
  s.add_dependency "net-scp"
  s.add_dependency "rake"
  s.add_dependency "torquebox-rake-support"
end