module I18n::Tasks
  module Command
    module Commands
      module EqBase
        def self.included(base)
          base.class_eval do
            cmd :eq_base,
                args: '[locale ...]',
                desc: I18n.t('i18n_tasks.cmd.desc.eq_base'),
                opt:  cmd_opts(:locales, :out_format)

            def eq_base(opt = {})
              opt_locales! opt
              opt_output_format! opt
              print_forest i18n.eq_base_keys(opt), opt, :eq_base_keys
            end
          end
        end
      end
    end
  end
end
