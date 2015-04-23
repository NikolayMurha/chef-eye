module ChefEyeCookbook
  class EyeProcess
    include Chef::Mixin::ShellOut

    attr_reader :node, :owner, :group, :type, :home
    attr_reader :eye_home, :eye_file, :eye_bin, :config_file

    def initialize(type, node, params)
      @node = node
      @owner = params[:owner]
      @group = params[:group]
      @type = type == 'local' ? 'local' : 'user'
      @home = @owner == 'root' ? '/var/run/eye' : Etc.getpwnam(@owner).dir
      if @type == 'local'
        @eye_file = params[:eye_file]
        @eye_home = params[:eye_home]
        @eye_bin = @node['chef_eye']['leye_bin']
      else
        @config_file = params[:eye_file]
        @eye_bin = @node['chef_eye']['eye_bin']
      end
      @pid_file = ::File.join(@eye_home || @home, '.eye', 'pid')
    end

    def run_command(*args)
      args.unshift @eye_bin
      opts = args.last.is_a?(Hash) ? args.pop : {}
      cmd = shell_out(*args, :user => @owner, :group => @owner, :env => environment)
      cmd.error! unless opts[:silent]
      cmd
    end

    def send_command(*args)
      return unless yield if block_given?
      run_command(*args) if running?
    end

    def send_command!(*args)
      raise 'Eye service is not running!' unless running?
      return unless yield if block_given?
      run_command(*args)
    end

    def application?(app)
      running? && oinfo(app).any?
    end

    def running?
      pid && Process.kill(0, pid) == 1
    rescue Errno::ESRCH
      false
    end

    def pid
      if ::File.exist?(@pid_file)
        ::File.read(@pid_file).to_i
      else
        false
      end
    end

    def environment
      env = {}
      env['HOME'] = @home
      env['EYE_FILE'] = @eye_file if @eye_file
      env['EYE_HOME'] = @eye_home if @eye_home
      env
    end

    def wait_stop(application = nil, timeout = 30)
      Chef::Log.debug("EyeProcess: wait stop applications #{timeout} seconds")
      wait(timeout) do
        oinfo(application).values.all? { |v| v == 'unmonitored' || v == 'stopping' }
      end
    end

    def wait(timeout, &block)
      start_time = Time.now
      end_time = start_time+timeout
      while true
        return true if block.call
        raise 'Wait timeout!' if Time.now > end_time
        sleep 1
      end
    end

    def oinfo(name = nil)
      cmd = run_command('oinfo')
      cmd.stdout.split("\n").each_with_object({}) do |i, obj|
        i = i.split
        next if name && name != i.first
        obj[i.first] = i.last.split(':').first
      end
    end

    class << self
      def from_service_config(node, config)
        ChefEyeCookbook::EyeProcess.new(config['type'], node, ChefEyeCookbook::Utils.symbolize_keys(config))
      end

      def form_service_resource(service_resource)
        ChefEyeCookbook::EyeProcess.new(service_resource.type, service_resource.node,
          owner: service_resource.owner,
          group: service_resource.group,
          eye_home: service_resource.eye_home,
          eye_file: service_resource.eye_file
        )
      end
    end
  end
end
