# coding: utf-8
require 'i18n/tasks/reports/base'
require 'terminal-table'
module I18n
  module Tasks
    module Reports
      class Terminal < Base
        include Term::ANSIColor

        def missing_keys(forest = task.missing_keys)
          forest = task.collapse_plural_nodes!(forest)
          if forest.present?
            print_title missing_title(forest)
            print_table headings: [cyan(bold('Locale')), cyan(bold 'Key'), 'Details'] do |t|
              t.rows = sort_by_attr!(forest_to_attr(forest)).map do |a|
                [{value: cyan(a[:locale]), alignment: :center}, cyan(a[:key]), wrap_string(key_info(a), 60)]
              end
            end
          else
            print_success I18n.t('i18n_tasks.missing.none')
          end
        end

        def icon(type)
          glyph = missing_type_info(type)[:glyph]
          {missing_used: red(glyph), missing_diff: yellow(glyph)}[type]
        end

        def used_keys(used_tree = task.used_tree(source_locations: true))
          print_title used_title(used_tree)
          keys_nodes = used_tree.keys.to_a
          if keys_nodes.present?
            keys_nodes.sort! { |a, b| a[0] <=> b[0] }
            keys_nodes.each do |key, node|
              usages = node.data[:source_locations]
              puts "#{bold "#{key}"} #{green(usages.size.to_s) if usages.size > 1}"
              usages.each do |u|
                line = u[:line].dup.tap { |line|
                  line.strip!
                  line.sub!(/(.*?)(#{key})(.*)$/) { dark($1) + underline($2) + dark($3) }
                }
                puts "  #{green "#{u[:src_path]}:#{u[:line_num]}"} #{line}"
              end
            end
          else
            print_error 'No key usages found'
          end
        end

        def unused_keys(tree = task.unused_keys)
          keys = tree.root_key_values(true)
          if keys.present?
            print_title unused_title(keys)
            print_locale_key_value_table keys
          else
            print_success I18n.t('i18n_tasks.unused.none')
          end
        end

        def eq_base_keys(tree = task.eq_base_keys)
          keys = tree.root_key_values(true)
          if keys.present?
            print_title eq_base_title(keys)
            print_locale_key_value_table keys
          else
            print_info cyan('No translations are the same as base value')
          end
        end

        def show_tree(tree)
          print_locale_key_value_table tree.root_key_values(true)
        end

        def forest_stats(forest, stats = task.forest_stats(forest))
          text = if stats[:locale_count] == 1
                   I18n.t('i18n_tasks.data_stats.text_single_locale', stats)
                 else
                   I18n.t('i18n_tasks.data_stats.text', stats)
                 end
          title = bold(I18n.t('i18n_tasks.data_stats.title', stats.slice(:locales)))
          print_info "#{cyan title} #{cyan text}"
        end

        private

        def print_locale_key_value_table(locale_key_values)
          if locale_key_values.present?
            print_table headings: [bold(cyan('Locale')), bold(cyan('Key')), 'Value'] do |t|
              t.rows = locale_key_values.map { |(locale, k, v)| [{value: cyan(locale), alignment: :center}, cyan(k), v.to_s] }
            end
          else
            puts 'ø'
          end
        end

        def print_title(title)
          log_stderr "#{bold title.strip} #{dark "|"} #{"i18n-tasks v#{I18n::Tasks::VERSION}"}"
        end

        def print_success(message)
          log_stderr bold(green "✓ #{I18n.t('i18n_tasks.cmd.encourage').sample} #{message}")
        end

        def print_error(message)
          log_stderr(bold red message)
        end

        def print_info(message)
          log_stderr message
        end

        def indent(txt, n = 2)
          spaces = ' ' * n
          txt.gsub /^/, spaces
        end

        def print_table(opts, &block)
          puts ::Terminal::Table.new(opts, &block)
        end

        def key_info(leaf)
          if leaf[:type] == :missing_used
            first_occurrence leaf
          else
            leaf[:value].to_s.strip
          end
        end

        def first_occurrence(leaf)
          usages = leaf[:data][:source_locations]
          first  = usages.first
          [green("#{first[:src_path]}:#{first[:line_num]}"),
           ("(#{usages.length - 1} more)" if usages.length > 1)].compact.join(' ')
        end

        def wrap_string(s, max)
          chars = []
          dist  = 0
          s.chars.each do |c|
            chars << c
            dist += 1
            if c == "\n"
              dist = 0
            elsif dist == max
              dist = 0
              chars << "\n"
            end
          end
          chars = chars[0..-2] if chars.last == "\n"
          chars.join
        end
      end
    end
  end
end
