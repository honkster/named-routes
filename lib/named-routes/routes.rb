module NamedRoutes
  class Routes
    class_inheritable_accessor :host, :prefix
    
    extend(Module.new do
      def instance
        @instance ||= new
      end

      def http
        SchemedUri.new(self, "http")
      end

      def https
        SchemedUri.new(self, "https")
      end

      def path(name, definition, include_prefix=true)
        full_definition = (include_prefix && prefix) ? File.join("", prefix, definition) : definition
        define_method name do |*args|
          self.class.eval(full_definition, [args.first].compact.first || {})
        end
        yield full_definition if block_given?
        full_definition
      end

      def eval(definition, params_arg={})
        params = Mash.new(params_arg)
        path_string = if params.empty?
          definition
        else
          definition.split("/").map do |segment|
            segment_value = segment[/^:(.*)/, 1]
            segment_value_parts = segment_value.to_s.split(".")
            segment_name = segment_value_parts[0]
            if segment_name
              param_name = params.delete(File.basename(segment_name, '.*').to_s)
              URI.escape([param_name, *segment_value_parts[1..-1]].join("."))
            else
              segment
            end
          end.join("/")
        end
        unless params.empty?
          path_string << "?#{escape_params(params).to_params.gsub("%20", "+")}"
        end
        path_string
      end

      # TODO: Create eval_without_prefix

      def escape_params(params={})
        params.inject({}) do |memo, kv|
          key, value = kv
          memo[URI.escape(key)] = if value.is_a?(Hash)
            escape_params(value)
          elsif value.is_a?(Array)
            value.map { |v| URI.escape(v.to_s) }
          else
            URI.escape(value.to_s)
          end
          memo
        end
      end

      def normalize(path)
        path.gsub(Regexp.new("^#{File.join("", prefix.to_s)}"), "/").gsub("//", "/")
      end

      def method_missing(method_name, *args, &block)
        if instance.respond_to?(method_name)
          instance.send(method_name, *args, &block)
        else
          super
        end
      end
    end)
  end
end
