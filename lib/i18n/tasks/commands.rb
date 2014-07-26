# coding: utf-8
require 'i18n/tasks/command/commander'
require 'i18n/tasks/command/options/shared'
require 'i18n/tasks/command/options/locales'
require 'i18n/tasks/command/options/trees'
require 'i18n/tasks/reports/terminal'
require 'i18n/tasks/reports/spreadsheet'

module I18n::Tasks
  class Commands < Command::Commander
    include Term::ANSIColor
    require 'highline/import'
    include Command::Options::Shared
    include Command::Options::Locales
    include Command::Options::Trees

    cmd :missing,
        args: '[locale ...]',
        desc: 'show missing translations',
        opt:  cmd_opts(:locales, :out_format, :missing_types)

    def missing(opt = {})
      opt_locales!(opt)
      opt_output_format!(opt)
      print_forest i18n.missing_keys(opt), opt, :missing_keys
    end

    cmd :unused,
        args: '[locale ...]',
        desc: 'show unused translations',
        opt:  cmd_opts(:locales, :out_format, :strict)

    def unused(opt = {})
      opt_locales! opt
      opt_output_format! opt
      print_forest i18n.unused_keys(opt), opt, :unused_keys
    end

    cmd :eq_base,
        args: '[locale ...]',
        desc: 'show translations equal to base value',
        opt:  [cmd_opt(:out_format)]

    def eq_base(opt = {})
      opt_locales! opt
      opt_output_format! opt
      print_forest i18n.eq_base_keys(opt), opt, :eq_base_keys
    end

    cmd :find,
        args: '[pattern]',
        desc: 'show where the keys are used in the code',
        opt:  cmd_opts(:out_format, :pattern)

    def find(opt = {})
      opt_output_format! opt
      opt[:filter] ||= opt.delete(:pattern) || opt[:arguments].try(:first)
      print_forest i18n.used_tree(key_filter: opt[:filter].presence, source_locations: true), opt, :used_keys
    end

    cmd :translate_missing,
        args: '[locale ...]',
        desc: 'translate missing keys with Google Translate',
        opt:  [cmd_opt(:locales).merge(desc: 'Locales to translate (comma-separated, default: all)'),
               cmd_opt(:locale).merge(short: :f, long: :from=, desc: 'Locale to translate from (default: base)'),
               cmd_opt(:out_format).except(:short)]

    def translate_missing(opt = {})
      opt_locales! opt
      opt_output_format! opt
      from       = opt_locale! opt, :from
      translated = (opt[:locales] - [from]).inject i18n.empty_forest do |result, locale|
        result.merge! i18n.google_translate_forest i18n.missing_tree(locale, from), from, locale
      end
      i18n.data.merge! translated
      log_stderr 'Translated:'
      print_forest translated, opt
    end

    cmd :add_missing,
        args: '[locale ...]',
        desc: 'add missing keys to locale data',
        opt:  [cmd_opt(:locales).merge(desc: 'Locales to add keys into (comma-separated, default: all)'),
               cmd_opt(:value).merge(desc: cmd_opt(:value)[:desc] + '. Default: %{value_or_human_key}'),
               cmd_opt(:out_format)]

    def add_missing(opt = {})
      opt_locales! opt
      opt_output_format! opt
      forest = i18n.missing_keys(opt).set_each_value!(opt[:value] || '%{value_or_human_key}')
      i18n.data.merge! forest
      log_stderr 'Added:'
      print_forest forest, opt
    end

    cmd :normalize,
        desc: 'normalize translation data: sort and move to the right files',
        opt:  [cmd_opt(:locales).merge(desc: 'Locales to normalize (comma-separated, default: all)'),
               {short: :p, long: :pattern_router, desc: 'Normalize using pattern router, moves keys per data.write.',
                conf:  {argument: false, optional: true}}]

    def normalize(opt = {})
      opt_locales! opt
      i18n.normalize_store! opt[:locales], opt[:pattern_router]
    end

    cmd :remove_unused,
        args: '[locale ...]',
        desc: 'remove unused keys',
        opt:  [cmd_opt(:locales).merge(desc: 'Locales to remove unused keys from (comma-separated, default: all)'),
               *cmd_opts(:out_format, :strict)]

    def remove_unused(opt = {})
      opt_locales! opt
      opt_output_format! opt
      unused_keys = i18n.unused_keys(opt)
      if unused_keys.present?
        terminal_report.unused_keys(unused_keys)
        unless ENV['CONFIRM']
          exit 1 unless agree(red "#{unused_keys.leaves.count} translations will be removed in #{bold opt[:locales] * ', '}#{red '.'} " + yellow('Continue? (yes/no)') + ' ')
        end
        removed = i18n.data.remove_by_key!(unused_keys)
        log_stderr "Removed #{unused_keys.leaves.count} keys"
        print_forest removed, opt
      else
        log_stderr bold green 'No unused keys to remove'
      end
    end

    cmd :config,
        args: '[section ...]',
        desc: 'display i18n-tasks configuration'

    def config(opts = {})
      cfg = i18n.config_for_inspect
      cfg = cfg.slice(*opts[:arguments]) if opts[:arguments]
      cfg = cfg.to_yaml
      cfg.sub! /\A---\n/, ''
      cfg.gsub! /^([^\s-].+?:)/, Term::ANSIColor.cyan(Term::ANSIColor.bold('\1'))
      puts cfg
    end

    cmd :xlsx_report,
        args: '[locale ...]',
        desc: 'save missing and unused translations to an Excel file',
        opt:  [cmd_opt(:locales),
               {short: :p, long: :path=, desc: 'Destination path', conf: {default: 'tmp/i18n-report.xlsx'}}]

    def xlsx_report(opt = {})
      begin
        require 'axlsx'
      rescue LoadError
        message = %Q(For spreadsheet report please add axlsx gem to Gemfile:\ngem 'axlsx', '~> 2.0')
        log_stderr Term::ANSIColor.red Term::ANSIColor.bold message
        exit 1
      end
      opt_locales! opt
      spreadsheet_report.save_report opt[:path], opt.except(:path)
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
        args: '[tree ...]',
        desc: 'merge locale data with [trees]',
        opt:  cmd_opts(:data_format, :stdin)

    def data_merge(opt = {})
      opt_data_format! opt
      forest = parse_forest_args(opt)
      merged = i18n.data.merge!(forest)
      print_forest merged, opt
    end

    cmd :data_write,
        args: '<tree>',
        desc: 'replace locale data with [tree]',
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

    cmd :tree_merge,
        args: '[tree ...]',
        desc: 'Merge [trees]', opt: cmd_opts(:data_format, :stdin)

    def tree_merge(opts = {})
      print_forest parse_forest_args(opts), opts
    end

    cmd :tree_filter,
        args: '<tree> <pattern>',
        desc: 'Filter [tree] by key pattern',
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
        desc: 'Rename [tree] keys by key pattern',
        opt:  cmd_opts(:data_format, :stdin) + [
            cmd_opt(:pattern).merge(short: :k, long: :key=, desc: 'Full key to rename (pattern). Required'),
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
        desc: 'Output [tree A] without the keys in [tree B]',
        opt:  cmd_opts(:data_format, :stdin)

    def tree_subtract_by_key(opt = {})
      opt_data_format! opt
      forests = args_with_stdin(opt).map { |src| parse_forest(src, opt) }
      forest  = forests.reduce(:subtract_by_key) || empty_forest
      print_forest forest, opt
    end

    cmd :tree_subtract_keys,
        args: '<tree> <keys>',
        desc: 'Output [tree] without the [keys]',
        opt:  cmd_opts(:keys, :data_format, :stdin)

    def tree_subtract_keys(opt = {})
      opt_data_format! opt
      opt_keys! opt
      result = parse_forest_arg!(opt).subtract_keys(opt[:keys] || [])
      print_forest result, opt
    end

    cmd :tree_set_value,
        args: '<tree> <pattern> <value>',
        desc: 'Set values of [tree] keys matching pattern',
        opt:  cmd_opts(:value, :data_format, :stdin, :pattern)

    def tree_set_value(opt = {})
      opt_data_format! opt
      forest  = parse_forest_arg!(opt)
      pattern = opt[:pattern] || opt[:arguments].try(:shift)
      value   = opt[:value] || opt[:arguments].try(:shift)
      raise CommandError.new('pass value (-v, --value)') if value.blank?
      forest.set_each_value!(value, pattern)
      print_forest forest, opt
    end

    cmd :tree_convert,
        args: '<tree>',
        desc: 'Convert tree from one format to another',
        opt:  [cmd_opt(:data_format).merge(short: :f, long: :from=),
               cmd_opt(:out_format).merge(short: :t, long: :to=),
               cmd_opt(:stdin)]

    def tree_convert(opt = {})
      opt_data_format! opt, :from
      opt_output_format! opt, :to
      forest = parse_forest_args opt.merge(format: opt[:from])
      print_forest forest, opt.merge(format: opt[:to])
    end

    cmd :irb, desc: 'REPL session within i18n-tasks context'

    def irb
      require 'i18n/tasks/console_context'
      ::I18n::Tasks::ConsoleContext.start
    end

    cmd :gem_path, desc: 'show path to the gem'

    def gem_path
      puts File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    end

  end
end
