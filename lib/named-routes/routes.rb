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

      def route(name, definition, include_prefix=true)
        full_definition = (include_prefix && prefix) ? File.join("", prefix, definition) : definition
        _defined_routes[name.to_s] = full_definition
        define_method name do |*args|
          self.class.eval(full_definition, [args.first].compact.first || {})
        end
        yield full_definition if block_given?
        full_definition
      end
      alias_method :path, :route
      alias_method :uri, :route

      def defined_routes
        (ancestors.reverse + [self]).inject({}) do |memo, klass|
          memo.merge!(klass._defined_routes) if klass.respond_to?(:_defined_routes)
          memo
        end
      end

      def _defined_routes
        @_defined_routes ||= {}
      end

      def eval(definition, params_arg={})
        params = Mash.new(params_arg)
        uri_string = if params.empty?
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
          uri_string << "?#{escape_params(params).to_params.gsub("%20", "+")}"
        end
        uri_string
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

      def normalize(uri)
        uri.gsub(Regexp.new("^#{File.join("", prefix.to_s)}"), "/").gsub("//", "/")
      end

      def as_json(*args)
        instance.as_json(*args)
      end

      def method_missing(method_name, *args, &block)
        if instance.respond_to?(method_name)
          instance.send(method_name, *args, &block)
        else
          super
        end
      end
    end)

    def eval(*args)
      self.class.eval(*args)
    end

    def as_json(*args)
      self.class.defined_routes
    end
  end
end
