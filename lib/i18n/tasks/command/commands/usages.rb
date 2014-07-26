module I18n::Tasks
  module Command
    module Commands
      module Usages
        def self.included(base)
          base.class_eval do
            cmd :find,
                args: '[pattern]',
                desc: 'show where the keys are used in the code',
                opt:  cmd_opts(:out_format, :pattern)

            def find(opt = {})
              opt_output_format! opt
              opt[:filter] ||= opt.delete(:pattern) || opt[:arguments].try(:first)
              print_forest i18n.used_tree(key_filter: opt[:filter].presence, source_locations: true), opt, :used_keys
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
          end
        end
      end
    end
  end
end
