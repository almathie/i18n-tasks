module I18n::Tasks
  module Command
    module Options
      module Trees
        def self.included(base)
          base.extend KlassMethods
          base.class_eval do
            enum_opt :data_format, %w(yaml json keys)
            enum_opt :out_format, ['terminal-table', *enum_opt(:data_format), 'inspect']
          end
        end

        def print_forest(forest, opt, version = :show_tree)
          format = opt[:format].to_s

          case format
            when 'terminal-table'
              terminal_report.send(version, forest)
            when 'inspect'
              puts forest.inspect
            when 'keys'
              puts forest.key_names(root: true)
            when *enum_opt(:data_format)
              puts i18n.data.adapter_dump forest, format
          end
        end

        INVALID_FORMAT_MSG = proc do |value, valid|
          I18n.t('i18n_tasks.cmd.errors.invalid_format', invalid: value, valid: valid * ', ')
        end

        def opt_output_format!(opt = {}, key = :format)
          opt[key] = parse_enum_opt opt[key], :out_format, &INVALID_FORMAT_MSG
        end

        def opt_data_format!(opt = {}, key = :format)
          opt[key] = parse_enum_opt opt[key], :data_format, &INVALID_FORMAT_MSG
        end

        def opt_args_keys!(opt = {})
          opt[:keys] = explode_list_opt(opt[:keys]) + Array(opt[:arguments])
        end

        def parse_forest_arg!(opt)
          src = opt[:stdin] ? $stdin.read : opt[:arguments].try(:shift)
          src or raise CommandError.new('pass forest')
          parse_forest(src, opt)
        end

        def parse_forest_args(opts, op = :merge!)
          args_with_stdin(opts).inject(i18n.empty_forest) do |forest, source|
            forest.send op, parse_forest(source, opts)
          end
        end

        def parse_forest(src, opt = {})
          format = opt_data_format!(opt)
          if format == 'keys'
            Data::Tree::Siblings.from_key_names parse_keys(src)
          else
            Data::Tree::Siblings.from_nested_hash i18n.data.adapter_parse(src, format)
          end
        end

        def parse_keys(src)
          explode_list_opt(src, /\s*[,\s\n]\s*/)
        end

        module KlassMethods
          def cmd_opts_schema
            super.merge(
                out_format:  enum_opt_attr(:f, :format=, enum_opt(:out_format)) { |valid_text, default_text|
                  I18n.t('i18n_tasks.cmd.args.desc.out_format', valid_text: valid_text, default_text: default_text)
                },
                data_format: enum_opt_attr(:f, :format=, enum_opt(:data_format)) { |valid_text, default_text|
                  I18n.t('i18n_tasks.cmd.args.desc.data_format', valid_text: valid_text, default_text: default_text)
                },
                keys:        {
                    short: :k,
                    long:  :keys=,
                    desc:  I18n.t('i18n_tasks.cmd.args.desc.keys'),
                    conf:  {as: Array, delimiter: /[+:,]/, argument: true, optional: false}
                }
            )
          end
        end
      end
    end
  end
end
