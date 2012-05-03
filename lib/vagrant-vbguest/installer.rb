module VagrantVbguest

  # Determinates if the GuestAdditions needs to be installed.
  # If so, it triggers the detection of the GuestAdditions iso file,
  # downloads that file if needed and  initiates the installation 
  # process by calling an appropriate Installer class (see 
  # {VagrantVbguest::Installers::Base})
  class Installer

    class NoInstallerFoundError < Vagrant::Errors::VagrantError
      error_namespace "vagrant.plugins.vbguest.errors.installer"
      error_key "no_install_script_for_platform"
    end

    class << self
      
      # Register an Installer implementation.
      # All Installer classes which wish to get picked automaticly
      # using their `#match?` method have to register.
      # Ad-hoc or small custom Installer meight not need to get
      # registered, but need to get passed as an config option (`installer`)
      # 
      # Registration takes a priority which defines how specific
      # the Installer matches a system. Low level installers, like 
      # "linux" or "bsd" use a small priority (2), while distribution
      # installers use higher priority (5). Installers matching a 
      # specific version of a distribution should use heigher
      # priority numbers.
      # 
      # @param [Class] installer_class A reference to the Installer class. 
      # @param [Fixnum] prio Priority describing how specific the Installer matches. (default: `5`)
      def register(installer_class, prio = 5) 
        @installers ||= {}
        @installers[prio] ||= []
        @installers[prio] << installer_class
      end

      # Returns an instance of the registrated Installer class which 
      # matches first (according to it's priority) or `nil` if none matches.
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

      return nil unless @options[:auto_update]

      if @options[:force] 
        @vm.ui.warn(I18n.t("vagrant.plugins.vbguest.installing_forced", :host => vb_version, :guest => guest_version))  
        install
      elsif needs_update?
        if @options[:no_install]
          @vm.ui.warn(I18n.t("vagrant.plugins.vbguest.guest_needs_update", :host => vb_version, :guest => guest_version))  
        else
          @vm.ui.warn(I18n.t("vagrant.plugins.vbguest.installing", :host => vb_version, :guest => guest_version))
          install
        end
      elsif needs_rebuild?
        @vm.ui.warn(I18n.t("vagrant.plugins.vbguest.rebuilding"))
        rebuild
      else
        @vm.ui.success(I18n.t("vagrant.plugins.vbguest.guest_ok", :version => guest_version))
      end
    ensure
      cleanup
    end

    def install
      if (installer = guest_installer)
        @options[:iso_path] ||= VagrantVbguest::Detector.new(@vm, @options).iso_path

        installer.install(iso_path) do |type, data|
          @vm.ui.info(data, :prefix => false, :new_line => false)
        end
      else
        raise NoInstallerFoundError, :method => 'install'
      end
    end

    def rebuild
      if (installer = guest_installer)
        installer.rebuild do |type, data|
          @vm.ui.info(data, :prefix => false, :new_line => false)
        end
      else
        raise NoInstallerFoundError, :method => 'rebuild'
      end
    end

    def needs_update?
      !(guest_version && vb_version == guest_version)
    end

    def needs_rebuild?
      if (installer = guest_installer)
        return !installer.installed?
      else
        raise NoInstallerFoundError, :method => 'check installation of'
      end
    end

    # Returns the version code of the VirtualBox Guest Additions 
    # available on the guest, or `nil` if none installed. 
    def guest_version
      guest_version = @vm.driver.read_guest_additions_version
      !guest_version ? nil : guest_version.gsub(/[-_]ose/i, '')
    end

    # Returns the version code of the Virtual Box *host*
    def vb_version
      @vm.driver.version
    end

    # Returns an installer instance for the current vm
    # This is either the one configured via `installer` option or
    # detected from all registered installers (see {Installer.detect})
    # 
    # @return [Installers::Base]
    def guest_installer
      if @options[:installer]
        @options[:installer].new(@vm)
      else
        Installer.detect(@vm)
      end
    end

    # Returns the local path of the GuestAdditions iso file
    # If the file is not available localy, it will try to download
    # the file using a appropriate out of {Vagrant::Downloaders} and 
    # return the temp path for that file
    #
    # @return [String] The path to the GuestAdditions iso file
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

