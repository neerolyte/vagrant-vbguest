module VagrantVbguest
  module Installers
    class Linux < Base

      def self.distro(vm)
        @@ditro ||= {}
        @@ditro[vm.uuid] ||= vm.guest.distro_dispatch
      end

      def self.match?(vm)
        vm.channel.test("uname | grep 'Linux'")
      end
      
      def tmp_path
        '/tmp/VBoxGuestAdditions.iso'
      end

      def mount_point
        '/mnt'
      end

      def install(iso_file, opts=nil, &block)
        @vm.ui.warn I18n.t("vagrant.plugins.vbguest.generic_linux_installer")
        upload(iso_file)
        vm.channel.sudo("mount #{tmp_path} -o loop #{mount_point}", opts, &block)
        vm.channel.sudo("#{mount_point}/VBoxLinuxAdditions.run --nox11", opts, &block)
        vm.channel.sudo("umount #{mount_point}", opts, &block)
        cleanup  
      end

    end
  end
end
VagrantVbguest::Installer.register(VagrantVbguest::Installers::Linux, 2)