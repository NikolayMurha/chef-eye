module ChefEyeCookbook
  module ConfigProvider
    def self.included(base)
      base.class_eval do
        use_inline_resources
        action :create do
          template new_resource.path do
            cookbook new_resource.cookbook ? new_resource.cookbook.to_s : cookbook_name.to_s
            source new_resource.source
            owner new_resource.owner
            group new_resource.group
            mode new_resource.mode
            helpers ::ChefEyeCookbook::ConfigRender::Methods
            variables(template_variables)
          end
        end

        action :delete do
          file new_resource.path do
            action :delete
          end
        end

        action :touch do
          file new_resource.path do
            action :touch
          end
        end

        def template_variables
          { name: new_resource.name, config: new_resource.config.config }
        end
      end
    end
  end
end
