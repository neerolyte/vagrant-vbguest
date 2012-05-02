module VagrantVbguest
  module Installers
    class Error < Vagrant::Errors::VagrantError
      error_namespace "vagrant.plugins.vbguest.errors.installer"
    end

    class Base

      def self.match?(vm)
        false
      end
      
      attr_reader :vm

      def initialize(vm)
        @vm = vm
      end      

      def upload(file)
        @vm.ui.info(I18n.t("vagrant.plugins.vbguest.start_copy_iso", :from => file, :to => tmp_path))
        @vm.channel.upload(file, tmp_path)
      end

      def cleanup
        @vm.channel.execute("rm #{tmp_path}") do |type, data|
          @vm.ui.error(data.chomp, :prefix => false)
        end
      end

      def tmp_path
      end

      def install(iso_file, opts=nil, &block)
      end

    end
  end
end