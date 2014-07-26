module I18n::Tasks
  module Command
    module Commands
      module Data
        def self.included(base)
          base.class_eval do
            cmd :normalize,
                args: '[locale ...]',
                desc: 'normalize translation data: sort and move to the right files',
                opt:  [cmd_opt(:locales).merge(desc: 'Locales to normalize (comma-separated, default: all)'),
                       {short: :p, long: :pattern_router, desc: 'Use pattern router: keys moved per config data.write',
                        conf:  {argument: false, optional: true}}]

            def normalize(opt = {})
              opt_locales! opt
              i18n.normalize_store! opt[:locales], opt[:pattern_router]
            end

            cmd :data,
                args: '[locale ...]',
                desc: 'show locale data',
                opt:  cmd_opts(:locales, :out_format)

            def data(opt = {})
              opt_locales! opt
              opt_output_format! opt
              print_forest i18n.data_forest(opt[:locales]), opt
            end

            cmd :data_merge,
                args: '<tree ...>',
                desc: 'merge locale data with trees',
                opt:  cmd_opts(:data_format, :stdin)

            def data_merge(opt = {})
              opt_data_format! opt
              forest = parse_forest_args(opt)
              merged = i18n.data.merge!(forest)
              print_forest merged, opt
            end

            cmd :data_write,
                args: '<tree>',
                desc: 'replace locale data with tree',
                opt:  cmd_opts(:data_format, :stdin)

            def data_write(opt = {})
              opt_data_format! opt
              forest = parse_forest_arg!(opt)
              i18n.data.write forest
              print_forest forest, opt
            end

            cmd :data_remove,
                args: '<tree>',
                desc: 'remove keys present in <tree> from data',
                opt:  cmd_opts(:data_format, :stdin)

            def data_remove(opt = {})
              opt_data_format! opt
              removed = i18n.data.remove_by_key!(parse_forest_arg!(opt))
              log_stderr 'Removed:'
              print_forest removed, opt
            end
          end
        end
      end
    end
  end
end
