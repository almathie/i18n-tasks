module I18n::Tasks
  module Command
    module Locales
      VALID_LOCALE_RE = /\A\w[\w\-_\.]*\z/i

      def self.included(base)
        base.extend KlassMethods
      end

      def parse_locales!(opt)
        opt[:locales] = locales_opt(opt[:arguments].presence || opt[:locales]).tap do |locales|
          locales.each do |locale|
            raise CommandError.new("Invalid locale: #{locale}") if VALID_LOCALE_RE !~ locale
          end
          log_verbose "locales for the command are #{locales.inspect}"
        end
      end

      def locales_opt(locales)
        return i18n.locales if locales == ['all'] || locales == 'all'
        if locales.present?
          locales = Array(locales).map { |v| v.strip.split(/\s*[\+,:]\s*/).compact.presence if v.is_a?(String) }.flatten
          locales = locales.map(&:presence).compact.map { |v| v == 'base' ? base_locale : v }
          locales
        else
          i18n.locales
        end
      end

      module KlassMethods
        def common_option_definitions
          super.merge(
              locale: {
                  short: :l,
                  long:  :locales=,
                  desc:  'Filter by locale(s), comma-separated list (en,fr) or all (default), or pass arguments without -l',
                  conf:  {as: Array, delimiter: /[+:,]/, default: 'all', argument: true, optional: false}
              }
          )
        end
      end
    end
  end
end
