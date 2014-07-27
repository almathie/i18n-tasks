module I18n::Tasks
  module Command
    module Options
      module Shared
        VALID_LOCALE_RE = /\A\w[\w\-_\.]*\z/i

        def self.included(base)
          base.extend KlassMethods
        end

        module KlassMethods
          def cmd_opts_schema
            super.merge(
                strict:        {
                    short: :s,
                    long:  :strict,
                    desc:  I18n.t('i18n_tasks.cmd.args.desc.strict')
                },
                stdin:         {
                    short: :s,
                    long:  :stdin,
                    desc:  I18n.t('i18n_tasks.cmd.args.desc.stdin'),
                    conf:  {default: false}
                },
                confirm: {
                    short: :y,
                    long:  :confirm,
                    desc:  I18n.t('i18n_tasks.cmd.args.desc.confirm'),
                    conf:  {default: false}
                },
                pattern:       {
                    short: :p,
                    long:  :pattern=,
                    desc:  I18n.t('i18n_tasks.cmd.args.desc.key_pattern'),
                    conf:  {argument: true, optional: false}
                },
                missing_types: {
                    short: :t,
                    long:  :types=,
                    desc:  I18n.t('i18n_tasks.cmd.args.desc.missing_types', valid: I18n::Tasks::MissingKeys.missing_keys_types * ', '),
                    conf: {as: Array, delimiter: /\s*[+:,]\s*/}
                },
                value:         {
                    short: :v,
                    long:  :value=,
                    desc:  I18n.t('i18n_tasks.cmd.args.desc.value'),
                    conf:  {argument: true, optional: false}
                }
            )
          end
        end
      end
    end
  end
end
