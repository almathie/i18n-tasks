# coding: utf-8
require 'i18n/tasks/commands_base'
require 'i18n/tasks/reports/terminal'
require 'i18n/tasks/reports/spreadsheet'

module I18n::Tasks
  class Commands < CommandsBase
    include Term::ANSIColor
    require 'highline/import'

    options = COMMON_OPTIONS = {
        locale:      {
            short: :l,
            long:  :locales=,
            desc:  'Filter by locale(s), comma-separated list (en,fr) or all (default), or pass arguments without -l',
            conf:  {as: Array, delimiter: /[+:,]/, default: 'all', argument: true, optional: false}
        },
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
        },
        strict:      {
            short: :s,
            long:  :strict,
            desc:  %Q(Do not infer dynamic key usage such as `t("category.\#{category.name}")`)
        },
        stdin:       {
            short: :s,
            long:  :stdin,
            desc:  'Read locale data from stdin before the arguments'
        },
        pattern:     {
            short: :p,
            long:  :pattern=,
            desc:  %(Filter by key pattern (e.g. 'common.*')),
            conf:  {argument: true, optional: false}
        },
        value:       {
            short: :v,
            long:  :value=,
            desc:  'Value, interpolates %{value}, %{human_key}, and %{value_or_human_key}',
            conf:  {argument: true, optional: false}
        }
    }

    cmd :missing, desc: 'show missing translations', opts: [
        *options.slice(:locale, :format).values,
        {short: :t, long: :types=, desc: 'Filter by type (types: used, diff)', conf: {as: Array, delimiter: /[+:,]/}}
    ]

    def missing(opt = {})
      parse_locales! opt
      print_locale_tree i18n.missing_keys(opt), opt, :missing_keys
    end

    cmd :unused, desc: 'show unused translations', opts: options.slice(:locale, :format, :strict).values

    def unused(opt = {})
      parse_locales! opt
      print_locale_tree i18n.unused_keys(opt), opt, :unused_keys
    end

    cmd :eq_base, desc: 'show translations equal to base value', opts: [options[:format]]

    def eq_base(opt = {})
      parse_locales! opt
      print_locale_tree i18n.eq_base_keys(opt), opt, :eq_base_keys
    end

    cmd :find, desc: 'show where the keys are used in the code', opts: options.slice(:format, :pattern).values

    def find(opt = {})
      opt[:filter] ||= opt.delete(:pattern) || opt[:arguments].try(:first)
      print_locale_tree i18n.used_tree(key_filter: opt[:filter].presence, source_locations: true), opt, :used_keys
    end

    cmd :data, desc: 'show locale data', opts: options.slice(:locale, :format).values

    def data(opt = {})
      parse_locales! opt
      print_locale_tree i18n.data_forest(opt[:locales]), opt
    end

    cmd :translate_missing, desc: 'translate missing keys with Google Translate', opts: [
        options[:locale].merge(desc: 'Locales to translate (comma-separated, default: all)'),
        {short: :f, long: :from=, desc: 'Locale to translate from (default: base)',
         conf:  {default: 'base', argument: true, optional: false}}
    ]

    def translate_missing(opt = {})
      opt[:from] = base_locale if opt[:from].blank? || opt[:from] == 'base'
      parse_locales! opt
      i18n.fill_missing_google_translate opt
    end

    cmd :add_missing, desc: 'add missing keys to the locales', opts: [
        options[:locale].merge(desc: 'Locales to add keys into (comma-separated, default: all)'),
        options[:value].merge(desc: options[:value][:desc] + '. Default: %{value_or_human_key}')
    ]

    def add_missing(opt = {})
      parse_locales! opt
      forest = i18n.missing_keys(opt).set_each_value!(opt[:value] || '%{value_or_human_key}')
      i18n.data.merge! forest
      print_locale_tree forest, opt
    end

    cmd :normalize, desc: 'normalize translation data: sort and move to the right files', opts: [
        options[:locale].merge(desc: 'Locales to normalize (comma-separated, default: all)'),
        {short: :p, long: :pattern_router, desc: 'Use pattern router, regardless of config.',
         conf:  {argument: false, optional: true}}
    ]

    def normalize(opt = {})
      parse_locales! opt
      i18n.normalize_store! opt[:locales], opt[:pattern_router]
    end

    cmd :remove_unused, desc: 'remove unused keys', opts: [
        options[:locale].merge(desc: 'Locales to remove unused keys from (comma-separated, default: all)'),
        options[:strict]
    ]

    def remove_unused(opt = {})
      parse_locales! opt
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

    cmd :xlsx_report, desc: 'save missing and unused translations to an Excel file', opts: [
        options[:locale],
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
      parse_locales! opt
      spreadsheet_report.save_report opt[:path], opt.except(:path)
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

    cmd :merge, desc: 'merge forests passed as arguments', opts: options.slice(:data_format, :stdin).values

    def merge(opts = {})
      print_locale_tree read_forest_from_args(opts), opts
    end

    cmd :select_by_key, desc: 'select subtree matching key pattern', opts: [
        options[:data_format],
        options[:stdin],
        options[:pattern]
    ]

    def select_by_key(opts = {})
      forest = read_forest_from_args(opts)
      unless opts[:pattern].blank?
        pattern_re = i18n.compile_key_pattern(opts[:pattern])
        forest     = forest.select_keys { |full_key, _node| full_key =~ pattern_re }
      end
      print_locale_tree forest, opts
    end

    cmd :subtract_by_key, desc: 'subtract keys of forest passed as arguments', opts: options.slice(:data_format, :stdin).values

    def subtract_by_key(opts = {})
      forest = args_with_stdin(opts).map { |src| parse_tree(src, opts) }
      forest = forest.reduce(:subtract_by_key)
      print_locale_tree forest, opts
    end

    cmd :rename_key, desc: 'rename all keys matching pattern', opts: [
        *options.slice(:data_format, :stdin).values,
        options[:pattern].merge(short: :k, long: :key=, desc: 'Full key to rename (pattern). Required'),
        options[:pattern].merge(short: :n, long: :name=, desc: 'New name, interpolates original name as %{key}. Required')
    ]

    def rename_key(opts = {})
      forest = read_forest_from_args(opts)
      key    = opts[:key]
      name   = opts[:name]
      raise CommandError.new('pass key (-k, --key)') if key.blank?
      raise CommandError.new('pass name (-n, --name)') if name.blank?
      forest.rename_each_key!(key, name)
      print_locale_tree forest, opts
    end

    cmd :set_value, desc: 'set all values matching key pattern', opts: options.slice(:value, :data_format, :stdin, :pattern).values

    def set_value(opts = {})
      forest = read_forest_from_args(opts)
      value  = opts[:value]
      raise CommandError.new('pass value (-v, --value)') if value.blank?
      forest.set_each_value!(value, opts[:pattern])
      print_locale_tree forest, opts
    end

    cmd :data_write, desc: 'write locale data passed as arguments', opts: options.slice(:data_format, :stdin).values

    def data_write(opts = {})
      forest = read_forest_from_args(opts)
      i18n.data.write forest
      print_locale_tree forest, opts
    end

    cmd :data_merge, desc: 'merge locale data passed as arguments', opts: options.slice(:data_format, :stdin).values

    def data_merge(opts = {})
      forest = read_forest_from_args(opts)
      i18n.data.merge! forest
      print_locale_tree forest, opts
    end
  end
end
