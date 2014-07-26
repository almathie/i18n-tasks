module I18n::Tasks
  module Command
    module Commands
      module Missing
        def self.included(base)
          base.class_eval do
            cmd :missing,
                args: '[locale ...]',
                desc: 'show missing translations',
                opt:  cmd_opts(:locales, :out_format, :missing_types)

            def missing(opt = {})
              opt_locales!(opt)
              opt_output_format!(opt)
              opt[:types] = explode_list_opt(opt[:types])
              print_forest i18n.missing_keys(opt), opt, :missing_keys
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
          end
        end
      end
    end
  end
end
