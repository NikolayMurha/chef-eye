module EyeCookbook
  module ConfigRender
    module Methods
      TYPED_FUNCTIONS = [:check, :trigger, :contact]
      BLOCKS = [:monitor_children]
      TYPED_BLOCKS = [:group, :process]
      FILTERED_KEYS = [:name, :type, :group, :application]

      KEY_MAP = {
        triggers: :trigger,
        checks: :check,
        processes: :process,
        groups: :group,
        nochecks: :nocheck,
        notriggers: :trigger,
        contact: :contact
      }

      def inflect(key)
        return KEY_MAP[key] if KEY_MAP[key]
        key
      end

      def render_config(config)
        render_hash(config).join("\n")
      end

      def render_hash(variable)
        ret = []
        variable = variable.delete_keys_recursive(FILTERED_KEYS)
        variable.each do |method, value|
          method = inflect(method.to_sym)
          render_strategy = "render_#{method}".to_sym
          if self.respond_to?(render_strategy)
            ret.push self.send(render_strategy, value)
          else
            ret.push "#{method}(#{value.to_source})"
          end
        end
        ret.compact.flatten.map {|i| "  #{i}"}
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
          ret = []
          value.each do |block_type, config|
            ret.push "#{name}(#{block_type.to_source}) do"
            ret.push render_hash(config)
            ret.push 'end'
          end
          ret
        end
      end

      TYPED_FUNCTIONS.each do |name|
        define_method "render_#{name}" do |value|
          ret = []
          value.each do |func_name, args|
            ret.push "#{name}(#{func_name.to_source}, #{args.to_source})"
          end
          ret
        end
      end
    end
    extend Methods
  end

  class ::Object
    def to_source
      self.to_s
    end
  end

  class ::Hash
    def to_source
      items = []
      each do |key, value|
        items.push "#{key.to_source} => #{value.to_source}"
      end
      "{#{items.join(', ')}}"
    end

    def delete_keys_recursive(keys)
      self.inject({}) do |h,(k,v)|
        next h if keys.include?(k)
        v = v.delete_keys_recursive(keys) if v.is_a?(::Hash)
        h[k] = v
        h
      end
    end
  end

  class ::String
    def to_source
      "'#{self.to_s}'"
    end
  end

  class ::Symbol
    def to_source
      ":#{self.to_s}"
    end
  end

  class ::Array
    def to_source
      "[#{map(&:to_source).join(', ')}]"
    end
  end
end
