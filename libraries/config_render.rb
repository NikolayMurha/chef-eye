# TODO: Think how to refactor this shit
unless defined?(EyeCookbook::ConfigRender)
  module EyeCookbook
    module ConfigRender
      module Methods
        TYPED_FUNCTIONS = [:check, :trigger]
        BLOCKS = [:monitor_children]
        TYPED_BLOCKS = [:group, :process, :contact_group]
        FILTERED_KEYS = [:name, :type, :group, :application]

        KEY_MAP = {
          triggers: :trigger,
          checks: :check,
          processes: :process,
          groups: :group,
          nochecks: :nocheck,
          notriggers: :trigger,
          contacts: :contact
        }

        attr_writer :source_mode

        def source_mode
          @source_mode ||= SOURCE_MODE_SYMBOLIZE_KEYS
        end

        def inflect(key)
          return KEY_MAP[key] if KEY_MAP[key]
          key
        end

        def render_config(config)
          render_hash(config).join("\n")
        end

        def render_logger(args)
          "logger(#{args.is_a?(Array) ? args.map(&:to_source).join(', ') : args.to_source })"
        end

        def render_hash(variable)
          ret = []
          variable = symbolize_keys(variable.delete_keys_recursive(FILTERED_KEYS))
          variable.each do |method, value|
            method = inflect(method)
            render_strategy = "render_#{method}".to_sym
            if self.respond_to?(render_strategy)
              ret.push send(render_strategy, value)
            else
              ret.push "#{method}(#{value.to_source(source_mode)})"
            end
          end
          ret.compact.flatten.map { |i| "  #{i}" }
        end

        def render_contact(value)
          value.each_with_object([]) do |(name, options), ret|
            options = symbolize_keys(options)
            args = []
            args.push((options[:name] || name).to_sym)
            args.push(options[:type].to_sym)
            args.push(options[:contact].to_s)
            args.push(options[:opts].to_h) if options[:opts]
            args.map! { |arg| arg.to_source(source_mode) }
            ret.push "contact(#{args.join(', ')})"
            ret
          end
        end

        BLOCKS.each do |name|
          define_method "render_#{name}" do |value|
            ret = []
            ret.push "#{name} do"
            ret.push render_hash(value)
            ret.push 'end'
            ret
          end
        end

        TYPED_BLOCKS.each do |name|
          define_method "render_#{name}" do |value|
            value.each_with_object([]) do |(block_type, config), ret|
              ret.push "#{name}(#{block_type.to_source(source_mode)}) do"
              ret.push render_hash(config)
              ret.push 'end'
            end
          end
        end

        TYPED_FUNCTIONS.each do |name|
          define_method "render_#{name}" do |value|
            value.each_with_object([]) do |(func_name, args), ret|
              ret.push "#{name}(#{func_name.to_sym.to_source(source_mode)}, #{args.to_source(source_mode)})"
            end
          end
        end

        def symbolize_keys(hash)
          hash.each_with_object({}) { |(key, val), h| h[key.to_sym] = val }
        end
      end
      extend Methods
    end
  end

  class Object
    SOURCE_MODE_SYMBOLIZE_KEYS = :symbolize_keys
    SOURCE_MODE_DEFAULT = false

    def to_source(_mode = SOURCE_MODE_DEFAULT)
      to_s
    end
  end

  class Hash
    def to_source(mode = SOURCE_MODE_DEFAULT)
      items = each_with_object([]) do |(key, value), i|
        key = key.to_sym if mode == SOURCE_MODE_SYMBOLIZE_KEYS
        i.push "#{key.to_source(mode)} => #{value.to_source(mode)}"
      end
      "{#{items.join(', ')}}"
    end

    def delete_keys_recursive(keys)
      each_with_object({}) do |(k, v), h|
        next h if keys.include?(k)
        v = v.delete_keys_recursive(keys) if v.is_a?(::Hash)
        h[k] = v
        h
      end
    end
  end

  class String
    def to_source(_mode = SOURCE_MODE_DEFAULT)
      "'#{self}'"
    end
  end

  class Symbol
    def to_source(_mode = SOURCE_MODE_DEFAULT)
      ":#{self}"
    end
  end

  class Array
    def to_source(mode = SOURCE_MODE_DEFAULT)
      "[#{map { |i| i.to_source(mode) }.join(', ')}]"
    end
  end
end
