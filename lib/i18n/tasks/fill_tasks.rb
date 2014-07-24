# coding: utf-8
module I18n::Tasks
  module FillTasks
    def fill_missing_value(opts = {})
      value = opts[:value] || ''
      base  = opts[:base_locale] || base_locale
      locales_for_update(opts).each do |locale|
        m = missing_keys(locales: [locale], base_locale: base).keys { |key, node|
          node.value = value.respond_to?(:call) ? value.call(key, locale, node) : value
          if node.data.key?(:path)
            # set path hint for the router
            node.data.update path: LocalePathname.replace_locale(node.data[:path], node.data[:locale], locale), locale: locale
          end
        }
        data[locale] = data[locale].merge! m
      end
    end

    def fill_missing_google_translate(opts = {})
      from    = opts[:from] || base_locale
      locales = (Array(opts[:locales]).presence || self.locales) - [from]
      locales.each do |locale|
        keys   = missing_tree(locale, from, false).key_names.map(&:to_s)
        values = google_translate(keys.zip(keys.map(&t_proc(from))), to: locale, from: from).map(&:last)

        data[locale] = data[locale].merge! Data::Tree::Node.new(
            key: locale,
            children: Data::Tree::Siblings.from_flat_pairs(keys.zip(values))
        ).to_siblings
      end
    end

    def locales_for_update(opts)
      LocaleList.normalize_locale_list(opts[:locales] || opts[:locale] || self.locales, base_locale)
    end
  end
end
