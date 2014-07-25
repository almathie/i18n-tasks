# coding: utf-8
require 'i18n/tasks/commands_base'
require 'i18n/tasks/command/shared_options'
require 'i18n/tasks/command/locales'
require 'i18n/tasks/command/forests'
require 'i18n/tasks/reports/terminal'
require 'i18n/tasks/reports/spreadsheet'

module I18n::Tasks
  class Commands < CommandsBase
    include Term::ANSIColor
    require 'highline/import'
    include Command::SharedOptions
    include Command::Locales
    include Command::Forests

    opt_def = option_schema

    cmd :missing, desc: 'show missing translations', opt: opt_def.slice(:locale, :format, :missing_types).values

    def missing(opt = {})
      opt_locales!(opt)
      opt_output_format!(opt)
      print_forest i18n.missing_keys(opt), opt, :missing_keys
    end

    cmd :unused, desc: 'show unused translations', opt: opt_def.slice(:locale, :format, :strict).values

    def unused(opt = {})
      opt_locales! opt
      opt_output_format! opt
      print_forest i18n.unused_keys(opt), opt, :unused_keys
    end

    cmd :eq_base, desc: 'show translations equal to base value', opt: [opt_def[:format]]

    def eq_base(opt = {})
      opt_locales! opt
      opt_output_format! opt
      print_forest i18n.eq_base_keys(opt), opt, :eq_base_keys
    end

    cmd :find, desc: 'show where the keys are used in the code', opt: opt_def.slice(:format, :pattern).values

    def find(opt = {})
      opt_output_format! opt
      opt[:filter] ||= opt.delete(:pattern) || opt[:arguments].try(:first)
      print_forest i18n.used_tree(key_filter: opt[:filter].presence, source_locations: true), opt, :used_keys
    end

    cmd :translate_missing, desc: 'translate missing keys with Google Translate', opt: [
        opt_def[:locale].merge(desc: 'Locales to translate (comma-separated, default: all)'),
        {short: :f, long: :from=, desc: 'Locale to translate from (default: base)',
         conf:  {default: 'base', argument: true, optional: false}},
        opt_def[:format].except(:short)
    ]

    def translate_missing(opt = {})
      opt[:from] = base_locale if opt[:from].blank? || opt[:from] == 'base'
      opt_locales! opt
      opt_output_format! opt
      from = opt[:from]
      translated_forest = (opt[:locales] - [from]).inject i18n.empty_forest do |result, locale|
        translated = i18n.google_translate_forest i18n.missing_tree(locale, from), from, locale
        i18n.data.merge! translated
        result.merge! translated
      end
      log_stderr 'Translated:'
      print_forest translated_forest, opt
    end

    cmd :add_missing, desc: 'add missing keys to locale data', opt: [
        opt_def[:locale].merge(desc: 'Locales to add keys into (comma-separated, default: all)'),
        opt_def[:value].merge(desc: opt_def[:value][:desc] + '. Default: %{value_or_human_key}'),
        opt_def[:format]
    ]

    def add_missing(opt = {})
      opt_locales! opt
      opt_output_format! opt
      forest = i18n.missing_keys(opt).set_each_value!(opt[:value] || '%{value_or_human_key}')
      i18n.data.merge! forest
      log_stderr 'Added:'
      print_forest forest, opt
    end

    cmd :normalize, desc: 'normalize translation data: sort and move to the right files', opt: [
        opt_def[:locale].merge(desc: 'Locales to normalize (comma-separated, default: all)'),
        {short: :p, long: :pattern_router, desc: 'Use pattern router, regardless of config.',
         conf:  {argument: false, optional: true}}
    ]

    def normalize(opt = {})
      opt_locales! opt
      i18n.normalize_store! opt[:locales], opt[:pattern_router]
    end

    cmd :remove_unused, desc: 'remove unused keys', opt: [
        opt_def[:locale].merge(desc: 'Locales to remove unused keys from (comma-separated, default: all)'),
        opt_def[:strict]
    ]

    def remove_unused(opt = {})
      opt_locales! opt
      unused_keys = i18n.unused_keys(opt)
      if unused_keys.present?
        terminal_report.unused_keys(unused_keys)
        unless ENV['CONFIRM']
          exit 1 unless agree(red "#{unused_keys.leaves.count} translations will be removed in #{bold opt[:locales] * ', '}#{red '.'} " + yellow('Continue? (yes/no)') + ' ')
        end
        i18n.remove_unused!(opt[:locales])
        $stderr.puts "Removed #{unused_keys.leaves.count} keys"
      else
        $stderr.puts bold green 'No unused keys to remove'
      end
    end

    cmd :config, desc: 'display i18n-tasks configuration'

    def config(opts = {})
      cfg = i18n.config_for_inspect
      cfg = cfg.slice(*opts[:arguments]) if opts[:arguments]
      cfg = cfg.to_yaml
      cfg.sub! /\A---\n/, ''
      cfg.gsub! /^([^\s-].+?:)/, Term::ANSIColor.cyan(Term::ANSIColor.bold('\1'))
      puts cfg
    end

    cmd :xlsx_report, desc: 'save missing and unused translations to an Excel file', opt: [
        opt_def[:locale],
        {long: :path=, desc: 'Destination path', conf: {default: 'tmp/i18n-report.xlsx'}}
    ]

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

    cmd :data, desc: 'show locale data', opt: opt_def.slice(:locale, :format).values

    def data(opt = {})
      opt_locales! opt
      opt_output_format! opt
      print_forest i18n.data_forest(opt[:locales]), opt
    end

    cmd :data_merge, desc: 'merge locale data with [trees]', opt: opt_def.slice(:data_format, :stdin).values

    def data_merge(opt = {})
      opt_data_format! opt
      forest = parse_forest_args(opt)
      merged = i18n.data.merge!(forest)
      print_forest merged, opt
    end

    cmd :data_write, desc: 'replace locale data with [trees]', opt: opt_def.slice(:data_format, :stdin).values

    def data_write(opt = {})
      opt_data_format! opt
      forest = parse_forest_args(opt)
      i18n.data.write forest
      print_forest forest, opt
    end


    cmd :tree_merge, desc: 'Merge [trees]', opt: opt_def.slice(:data_format, :stdin).values

    def tree_merge(opts = {})
      print_forest parse_forest_args(opts), opts
    end

    cmd :tree_select_by_key, desc: 'Filter [trees] by key pattern', opt: [
        opt_def[:data_format],
        opt_def[:stdin],
        opt_def[:pattern]
    ]
    def tree_select_by_key(opt = {})
      opt_data_format! opt
      forest = parse_forest_args(opt)
      unless opt[:pattern].blank?
        pattern_re = i18n.compile_key_pattern(opt[:pattern])
        forest     = forest.select_keys { |full_key, _node| full_key =~ pattern_re }
      end
      print_forest forest, opt
    end

    cmd :tree_subtract_by_key, desc: '[Tree A] except the keys also in [tree B]', opt: opt_def.slice(:data_format, :stdin).values

    def tree_subtract_by_key(opt = {})
      opt_data_format! opt
      forests = args_with_stdin(opt).map { |src| parse_forest(src, opt) }
      forest  = forests.reduce(:subtract_by_key) || empty_forest
      print_forest forest, opt
    end

    cmd :tree_rename_key, desc: 'Rename [tree] keys by key pattern', opt: opt_def.slice(:data_format, :stdin).values + [
        opt_def[:pattern].merge(short: :k, long: :key=, desc: 'Full key to rename (pattern). Required'),
        opt_def[:pattern].merge(short: :n, long: :name=, desc: 'New name, interpolates original name as %{key}. Required')
    ]

    def tree_rename_key(opt = {})
      opt_data_format! opt
      forest = parse_forest_args(opt)
      key    = opt[:key]
      name   = opt[:name]
      raise CommandError.new('pass full key to rename (-k, --key)') if key.blank?
      raise CommandError.new('pass new name (-n, --name)') if name.blank?
      forest.rename_each_key!(key, name)
      print_forest forest, opt
    end

    cmd :tree_set_value, desc: 'Set values of [tree] keys matching pattern', opt: opt_def.slice(:value, :data_format, :stdin, :pattern).values

    def tree_set_value(opt = {})
      opt_data_format! opt
      forest = parse_forest_args(opt)
      value  = opt[:value]
      raise CommandError.new('pass value (-v, --value)') if value.blank?
      forest.set_each_value!(value, opt[:pattern])
      print_forest forest, opt
    end

    cmd :tree_convert, desc: 'Convert tree from one format to another', opt: [
        opt_def[:data_format].merge(short: :f, long: :from=),
        opt_def[:format].merge(short: :t, long: :to=),
        opt_def[:stdin]
    ]
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
