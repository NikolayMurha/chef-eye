module EyeCookbook
  module Utils
    def self.services(node)
      services = node['eye']['services']
      services = if services.is_a?(Array)
                   Hash[services.zip(Array.new(services.size, {}))]
                 else
                   services.to_hash
                 end
      node['eye']['applications'].each do |_, options|
        services[options['owner']] = {} unless services[options['owner']]
      end
      services
    end
  end
end
