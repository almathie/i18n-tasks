module I18n::Tasks
  module Command
    module Options

      def self.included(base)
        base.extend KlassMethods
      end

      def explode_list_opt(list_opt, delim = /\s*[\+,:]\s*/)
        Array(list_opt).compact.map { |v| v.strip.split(delim).compact.presence }.flatten.map(&:presence).compact
      end

      module KlassMethods
        def cmd_opts(*args)
          option_schema_cached.values_at(*args)
        end

        def cmd_opt(arg)
          option_schema_cached[arg]
        end

        def option_schema_cached
          @option_schema ||= option_schema
        end

        def option_schema
          {}
        end

        def enum_option_attr(short, long, name, valid)
          {short: short, long: long.to_sym, desc: "#{name}: #{valid * ', '}. Default: #{valid.first}",
           conf:  {default: valid.first, argument: true, optional: false}}
        end
      end
    end
  end
end
