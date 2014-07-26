module I18n::Tasks
  module Command
    module Options
      module Locales
        VALID_LOCALE_RE = /\A\w[\w\-_\.]*\z/i

        def self.included(base)
          base.extend KlassMethods
        end

        def opt_locales!(opt)
          argv = Array(opt[:arguments]) + Array(opt[:locales])
          if argv == ['all'] || argv == 'all' || argv.blank?
            locales = i18n.locales
          else
            locales = argv.map { |v|
              v.strip.split(/\s*[\+,:]\s*/).compact.presence if v.is_a?(String)
            }.flatten.map(&:presence).compact.map { |v|
              v == 'base' ? base_locale : v
            }
          end
          locales.each do |locale|
            raise CommandError.new("Invalid locale: #{locale}") if VALID_LOCALE_RE !~ locale
          end
          log_verbose "locales for the command are #{locales.inspect}"
          opt[:locales] = locales
        end

        def opt_locale!(opt, key = :locale)
          val      = opt[key]
          opt[key] = base_locale if val.blank? || val == 'base'
          opt[key]
        end

        module KlassMethods
          def option_schema
            super.merge(
                locales: {
                    short: :l,
                    long:  :locales=,
                    desc:  'Filter by locale(s), comma-separated list (en,fr) or all (default), or pass arguments without -l',
                    conf:  {as: Array, delimiter: /[+:,]/, default: 'all', argument: true, optional: false}
                },
                locale:  {
                    short: :l,
                    long:  :locale=,
                    desc:  'Locale. Default: base',
                    conf:  {default: 'base', argument: true, optional: false}
                }
            )
          end
        end
      end
    end
  end
end
