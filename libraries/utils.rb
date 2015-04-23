module ChefEyeCookbook
  module Utils
    class << self
      def services(node)
        services = node['chef_eye']['services']
        services = services.is_a?(Array) ? Hash[services.zip(Array.new(services.size, {}))] : services.to_hash
        node['chef_eye']['applications'].each do |_, options|
          services[options['owner']] ||= {} if options['type'] != 'local'
        end
        services.each_with_object({}) do |(k, v), obj|
          obj[k] = service_config(k, v)
        end
      end

      def service_config(user_name, config)
        {
          'type' => 'user',
          'owner' => user_name,
          'group' => user_name,
          'service_name' => "eye_#{user_name}",
          'config_dir' => "/etc/eye/#{user_name}",
          'eye_file' => "/etc/eye/#{user_name}.eye",
          'config' => {
            'logger' => "/var/log/eye/#{user_name}.log"
          }
        }.merge!(config || {})
      end

      def symbolize_keys(hash)
        hash.each_with_object({}) { |(key, val), h| h[key.to_sym] = val }
      end
    end
  end
end
