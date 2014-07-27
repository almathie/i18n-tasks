module I18n::Tasks
  module Command
    module Commands
      module Meta
        def self.included(base)
          base.class_eval do

            cmd :config,
                args: '[section ...]',
                desc: 'display i18n-tasks configuration'

            def config(opts = {})
              cfg = i18n.config_for_inspect
              cfg = cfg.slice(*opts[:arguments]) if opts[:arguments]
              cfg = cfg.to_yaml
              cfg.sub! /\A---\n/, ''
              cfg.gsub! /^([^\s-].+?:)/, Term::ANSIColor.cyan(Term::ANSIColor.bold('\1'))
              puts cfg
            end

            cmd :gem_path, desc: 'show path to the gem'

            def gem_path
              puts I18n::Tasks.gem_path
            end

            cmd :irb, desc: 'start REPL session within i18n-tasks context'

            def irb
              require 'i18n/tasks/console_context'
              ::I18n::Tasks::ConsoleContext.start
            end
          end
        end
      end
    end
  end
end
