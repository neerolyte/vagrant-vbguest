module VagrantVbguest

  # Handles the guest addins installation process

  class Installer

    class << self
      def register(installer_class, prio = 5) 
        @installers ||= {}
        @installers[prio] ||= []
        @installers[prio] << installer_class
      end

      def detect(vm)
        @installers.keys.sort.reverse.each do |prio|
          klass = @installers[prio].detect { |k| k.match?(vm) }
          return klass.new(vm) if klass
        end
        return nil
      end
    end

    def initialize(vm, options = {})
      @env = {
        :ui => vm.ui,
        :tmp_path => vm.env.tmp_path
      }
      @vm = vm
      @iso_path = nil
      @options = options
    end

    def run!
      @options[:auto_update] = true
      run
    end

    def run
      raise Vagrant::Errors::VMNotCreatedError if !@vm.created?
      raise Vagrant::Errors::VMInaccessible if !@vm.state == :inaccessible
      raise Vagrant::Errors::VMNotRunningError if @vm.state != :running

      if @options[:auto_update]

        @vm.ui.success(I18n.t("vagrant.plugins.vbguest.guest_ok", :version => guest_version)) unless needs_update?
        @vm.ui.warn(I18n.t("vagrant.plugins.vbguest.check_failed", :host => vb_version, :guest => guest_version)) if @options[:no_install]

        if @options[:force] || (!@options[:no_install] && needs_update?)
          @vm.ui.warn(I18n.t("vagrant.plugins.vbguest.installing#{@options[:force] ? '_forced' : ''}", :host => vb_version, :guest => guest_version))

          if (installer = guest_installer)
            @options[:iso_path] ||= VagrantVbguest::Detector.new(@vm, @options).iso_path

            installer.install(iso_path) do |type, data|
              @vm.ui.info(data, :prefix => false, :new_line => false)
            end
          else
            @vm.ui.error(I18n.t("vagrant.plugins.vbguest.no_install_script_for_platform"))
          end
          
        end
      end
    ensure
      cleanup
    end

    def needs_update?
      !(guest_version && vb_version == guest_version)
    end

    def guest_version
      guest_version = @vm.driver.read_guest_additions_version
      !guest_version ? nil : guest_version.gsub(/[-_]ose/i, '')
    end

    def vb_version
      @vm.driver.version
    end

    def guest_installer
      if @options[:installer]
        @options[:installer].new(@vm)
      else
        Installer.detect(@vm)
      end
    end

    def iso_path
      @iso_path ||= begin
        @env[:iso_url] ||= @options[:iso_path].gsub '$VBOX_VERSION', vb_version

        if local_iso?
          @env[:iso_url]
        else
          # :TODO: This will also raise, if the iso_url points to an invalid local path
          raise VagrantVbguest::Errors::DownloadingDisabledError.new(:from => @env[:iso_url]) if @options[:no_remote]
          @download = VagrantVbguest::Download.new(@env)
          @download.download
          @download.temp_path
        end
      end
    end

    def local_iso?
      ::File.file?(@env[:iso_url])
    end

    def cleanup
      @download.cleanup if @download
    end

  end
end

