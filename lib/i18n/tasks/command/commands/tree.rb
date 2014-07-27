module I18n::Tasks
  module Command
    module Commands
      module Tree
        def self.included(base)
          base.class_eval do

            cmd :tree_merge,
                args: '<tree ...>',
                desc: 'merge trees', opt: cmd_opts(:data_format, :stdin)

            def tree_merge(opts = {})
              print_forest parse_forest_args(opts), opts
            end

            cmd :tree_filter,
                args: '<tree> <pattern>',
                desc: 'filter tree by key pattern',
                opt:  cmd_opts(:data_format, :stdin, :pattern)

            def tree_filter(opt = {})
              opt_data_format! opt
              forest  = parse_forest_arg!(opt)
              pattern = opt[:pattern] || opt[:arguments].try(:shift)
              unless opt[:pattern].blank?
                pattern_re = i18n.compile_key_pattern(pattern)
                forest     = forest.select_keys { |full_key, _node| full_key =~ pattern_re }
              end
              print_forest forest, opt
            end

            cmd :tree_rename_key,
                args: '<tree> <key> <name>',
                desc: 'rename tree node',
                opt:  cmd_opts(:data_format, :stdin) + [
                    cmd_opt(:pattern).merge(short: :k, long: :key=, desc: 'Full key (pattern) to rename. Required'),
                    cmd_opt(:pattern).merge(short: :n, long: :name=, desc: 'New name, interpolates original name as %{key}. Required')]

            def tree_rename_key(opt = {})
              opt_data_format! opt
              forest = parse_forest_arg!(opt)
              key    = opt[:key] || opt[:arguments].try(:shift)
              name   = opt[:name] || opt[:arguments].try(:shift)
              raise CommandError.new('pass full key to rename (-k, --key)') if key.blank?
              raise CommandError.new('pass new name (-n, --name)') if name.blank?
              forest.rename_each_key!(key, name)
              print_forest forest, opt
            end

            cmd :tree_subtract_by_key,
                args: '<tree A> <tree B>',
                desc: 'tree A minus the keys in tree B',
                opt:  cmd_opts(:data_format, :stdin)

            def tree_subtract_by_key(opt = {})
              opt_data_format! opt
              forests = args_with_stdin(opt).map { |src| parse_forest(src, opt) }
              forest  = forests.reduce(:subtract_by_key) || empty_forest
              print_forest forest, opt
            end

            cmd :tree_subtract_keys,
                args: '<tree> <keys>',
                desc: 'tree minus the keys',
                opt:  cmd_opts(:keys, :data_format, :stdin)

            def tree_subtract_keys(opt = {})
              opt_data_format! opt
              opt_args_keys! opt
              result = parse_forest_arg!(opt).subtract_keys(opt[:keys] || [])
              print_forest result, opt
            end

            cmd :tree_set_value,
                args: '<tree> <value>',
                desc: 'set values of keys, optionally match a pattern',
                opt:  cmd_opts(:value, :data_format, :stdin, :pattern)

            def tree_set_value(opt = {})
              opt_data_format! opt
              forest  = parse_forest_arg!(opt)
              value   = opt[:value] || opt[:arguments].try(:shift)
              pattern = opt[:pattern]
              raise CommandError.new('pass value (-v, --value)') if value.blank?
              forest.set_each_value!(value, pattern)
              print_forest forest, opt
            end

            cmd :tree_convert,
                args: '<tree>',
                desc: 'convert tree between formats',
                opt:  [cmd_opt(:data_format).merge(short: :f, long: :from=),
                       cmd_opt(:out_format).merge(short: :t, long: :to=),
                       cmd_opt(:stdin)]

            def tree_convert(opt = {})
              opt_data_format! opt, :from
              opt_output_format! opt, :to
              forest = parse_forest_args opt.merge(format: opt[:from])
              print_forest forest, opt.merge(format: opt[:to])
            end
          end
        end
      end
    end
  end
end
