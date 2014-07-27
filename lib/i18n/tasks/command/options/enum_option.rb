module I18n::Tasks
  module Command
    module Options
      module EnumOption

        def self.included(base)
          base.extend KlassMethods
        end

        delegate :enum_opt, :enum_opt_valid?, to: :class

        DEFAULT_ENUM_OPT_ERROR = proc { |bad, good|
          I18n.t('i18n_tasks.cmd.enum_opt.invalid_one', invalid: bad, valid: good * ', ')
        }
        def parse_enum_opt(value, valid, &error_msg)
          error_msg ||= DEFAULT_ENUM_OPT_ERROR
          valid     = enum_opt(valid) if Symbol === valid
          return valid.first unless value.present?
          if enum_opt_valid?(valid, value)
            value
          else
            raise CommandError.new error_msg.call(value, valid)
          end
        end

        DEFAULT_ENUM_LIST_ERROR = proc { |bad, good|
          I18n.t('i18n_tasks.cmd.enum_opt.invalid_list', invalid: bad * ', ', valid: good * ', ')
        }
        def parse_enum_list_opt(values, valid, &error_msg)
          error_msg ||= DEFAULT_ENUM_LIST_ERROR
          values    = explode_list_opt(values)
          invalid   = values - valid.map(&:to_s)
          if invalid.empty?
            values
          else
            raise CommandError.new error_msg.call(invalid, valid)
          end
        end

        private

        module KlassMethods
          def enum_opt(name, list = nil)
            @enum_valid ||= {}
            if list
              @enum_valid[name] = list
            else
              @enum_valid[name]
            end
          end

          def enum_opt_valid?(valid, value)
            valid.include?(value)
          end

          DEFAULT_ENUM_OPT_DESC = proc { |valid, default|
            I18n.t('i18n_tasks.cmd.enum_opt.desc.default', valid_text: valid, default_text: default)
          }

          def enum_opt_attr(short, long, valid, &desc)
            desc ||= DEFAULT_ENUM_OPT_DESC
            {short: short, long: long.to_sym,
             desc:  desc.call(valid * ', ', I18n.t('i18n_tasks.cmd.args.default_text', value: valid.first)),
             conf:  {default: valid.first, argument: true, optional: false}}
          end
        end
      end
    end
  end
end
