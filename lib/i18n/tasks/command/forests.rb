module I18n::Tasks
  module Command
    module Forests
      VALID_DATA_FORMATS = %w(yaml json)
      VALID_OUT_FORMATS = ['terminal-table', *VALID_DATA_FORMATS, 'keys', 'inspect']

      def self.included(base)
        base.extend KlassMethods
      end

      def print_forest(forest, opt, version = :show_tree)
        format = opt[:format].to_s
        raise CommandError.new("unknown format: #{format}. Valid formats are: #{VALID_OUT_FORMATS * ', '}.") unless VALID_OUT_FORMATS.include?(format)
        case format
          when 'terminal-table'
            terminal_report.send(version, forest)
          when 'inspect'
            puts forest.inspect
          when 'keys'
            puts forest.key_names(root: true)
          when *VALID_DATA_FORMATS
            puts i18n.data.adapter_dump forest, format
        end
      end

      def opt_output_format!(opt = {}, key = :format)
        opt[key] ||= VALID_OUT_FORMATS.first
      end

      def opt_data_format!(opt = {}, key = :format)
        opt[key] ||= VALID_DATA_FORMATS.first
      end

      def parse_forest_args(opts, op = :merge!)
        args_with_stdin(opts).inject(i18n.empty_forest) do |forest, source|
          forest.send op, parse_forest(source, opts)
        end
      end

      def parse_forest(src, opt = {})
        hash = i18n.data.adapter_parse src, opt[:format] || VALID_DATA_FORMATS.first
        Data::Tree::Siblings.from_nested_hash hash
      end

      module KlassMethods
        def option_schema
          super.merge(
              format:      enum_option_attr(:f, :format, 'Output format', VALID_OUT_FORMATS),
              data_format: enum_option_attr(:f, :format, 'Data format', VALID_DATA_FORMATS)
          )
        end
      end
    end
  end
end
