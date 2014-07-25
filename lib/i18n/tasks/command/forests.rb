module I18n::Tasks
  module Command
    module Forests
      VALID_DATA_FORMATS = %w(yaml json)
      VALID_TREE_FORMATS = ['terminal-table', *VALID_DATA_FORMATS, 'keys', 'inspect']

      def self.included(base)
        base.extend KlassMethods
      end

      def read_forest_from_args(opts, op = :merge!)
        args_with_stdin(opts).inject(i18n.empty_forest) { |f, src| f.send op, parse_tree(src, opts) }
      end

      def parse_tree(src, opt = {})
        Data::Tree::Siblings.from_nested_hash(
            i18n.data.adapter_parse src, i18n.data.adapter_by_name(opt[:format] || VALID_DATA_FORMATS.first)
        )
      end

      def print_forest(tree, opt, version = :show_tree)
        format = opt[:format]
        raise CommandError.new("unknown format: #{format}. Valid formats are: #{VALID_TREE_FORMATS * ', '}.") unless VALID_TREE_FORMATS.include?(format)
        case format
          when 'terminal-table'
            terminal_report.send(version, tree)
          when 'inspect'
            puts tree.inspect
          when 'keys'
            puts tree.key_names(root: true)
          when *VALID_DATA_FORMATS
            puts i18n.data.adapter_dump tree, i18n.data.adapter_by_name(format)
        end
      end

      def parse_output_format!(opt = {})
        opt[:format] ||= VALID_TREE_FORMATS.first
      end

      def parse_data_format!(opt = {})
        opt[:format] ||= VALID_DATA_FORMATS.first
      end

      module KlassMethods
        def common_option_definitions
          super.merge(
              format:      {
                  short: :f,
                  long:  :format=,
                  desc:  "Output format: #{VALID_TREE_FORMATS * ', '}. Default: #{VALID_TREE_FORMATS.first}",
                  conf:  {default: VALID_TREE_FORMATS.first, argument: true, optional: false}
              },
              data_format: {
                  short: :f,
                  long:  :format=,
                  desc:  "Data format: #{VALID_DATA_FORMATS * ', '}. Default: #{VALID_DATA_FORMATS.first}",
                  conf:  {default: VALID_DATA_FORMATS.first, argument: true, optional: false}
              }
          )
        end
      end
    end
  end
end
