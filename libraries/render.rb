
#TODO Think how to refactor this shit
module EyeCookbook
  module ConfigRender
    module Methods
      MAPPED_FUNCTIONS = {
        contact: [Symbol, Symbol, String, Hash]
      }

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

      def source_mode=(source_mode)
        @source_mode = source_mode
      end

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

      def render_hash(variable)
        ret = []
        variable = symbolize_keys(variable.delete_keys_recursive(FILTERED_KEYS))
        variable.each do |method, value|
          method = inflect(method)
          render_strategy = "render_#{method}".to_sym
          if self.respond_to?(render_strategy)
            ret.push self.send(render_strategy, value)
          else
            ret.push "#{method}(#{value.to_source(source_mode)})"
          end
        end
        ret.compact.flatten.map {|i| "  #{i}"}
      end

      MAPPED_FUNCTIONS.each do |name, types|
        define_method "render_#{name}" do |value|
          ret = []
          value.each do |args|
            args.each_index {|i| args[i] = to_type(args[i], types[i]) }
            ret.push "#{name}(#{args.map {|arg| arg.to_source(source_mode) }.join(', ')})"
          end
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
          ret = []
          value.each do |block_type, config|
            ret.push "#{name}(#{block_type.to_source(source_mode)}) do"
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
            ret.push "#{name}(#{func_name.to_sym.to_source(source_mode)}, #{args.to_source(source_mode)})"
          end
          ret
        end
      end

      def symbolize_keys(hash)
        h = {}
        hash.each { |key, val| h[key.to_sym] = val }
        h
      end

      def to_type(value, type)
        return value.to_s if type == String && value.respond_to?(:to_s)
        return value.to_h if type == Hash && value.respond_to?(:to_h)
        return value.to_i if type == Integer && value.respond_to?(:to_i)
        return value.to_sym if type == Symbol && value.respond_to?(:to_sym)
        value
      end
    end
    extend Methods
  end

  class ::Object
    SOURCE_MODE_SYMBOLIZE_KEYS = :symbolize_keys
    SOURCE_MODE_DEFAULT = false

    def to_source(mode = SOURCE_MODE_DEFAULT)
      self.to_s
    end
  end

  class ::Hash
    def to_source(mode = SOURCE_MODE_DEFAULT)
      items = []
      each do |key, value|
        key = key.to_sym if mode == SOURCE_MODE_SYMBOLIZE_KEYS
        items.push "#{key.to_source(mode)} => #{value.to_source(mode)}"
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
    def to_source(mode = SOURCE_MODE_DEFAULT)
      "'#{self.to_s}'"
    end
  end

  class ::Symbol
    def to_source(mode = SOURCE_MODE_DEFAULT)
      ":#{self.to_s}"
    end
  end

  class ::Array
    def to_source(mode = SOURCE_MODE_DEFAULT)
      "[#{map{|i| i.to_source(mode)}.join(', ')}]"
    end
  end
end
