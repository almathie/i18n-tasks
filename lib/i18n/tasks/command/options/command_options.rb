require 'i18n/tasks/command/options/enum_option'

module I18n::Tasks
  module Command
    module Options
      module CommandOptions

        def self.included(base)
          base.extend KlassMethods
        end

        module KlassMethods
          def cmd_opts(*args)
            cmd_opts_cached.values_at(*args)
          end

          def cmd_opt(arg)
            cmd_opts_cached[arg]
          end

          def cmd_opts_cached
            @cmd_opts_cached ||= cmd_opts_schema
          end

          def cmd_opts_schema
            {}
          end
        end
      end
    end
  end
end
