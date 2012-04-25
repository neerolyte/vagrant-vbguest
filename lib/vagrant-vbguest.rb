require 'vagrant'
require "vagrant-vbguest/errors"

# Add our custom translations to the load path
I18n.load_path << File.expand_path("../../locales/en.yml", __FILE__)

module VagrantVbguest

  autoload :Action, 'vagrant-vbguest/action'
  autoload :Config, 'vagrant-vbguest/config'
  autoload :Command, 'vagrant-vbguest/command'
  autoload :Errors, 'vagrant-vbguest/errors'

  autoload :Detector, "vagrant-vbguest/detector"
  autoload :Download, "vagrant-vbguest/download"
  autoload :Installer, "vagrant-vbguest/installer"

  class Plugin < Vagrant.plugin("1")
    name "vbguest management"
    description <<-DESC
    Provides automatic and/or manual management of the 
    VirtualBox Guest Additions inside the Vagrant environment.
    DESC

    config('vbguest') { Config }
    command('vbguest') { Command }
    Vagrant.actions[:start].use VagrantVbguest::Action
    # I would really like to do this:
    # action(:start) {
    #   use VagrantVbguest::Action
    # }
  end
end