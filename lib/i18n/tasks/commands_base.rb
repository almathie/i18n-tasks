# coding: utf-8
require 'i18n/tasks/slop_command'
module I18n::Tasks
  class CommandsBase
    include ::I18n::Tasks::Logging

    def initialize(i18n = nil)
      @i18n = i18n
    end

    def args_with_stdin(opt)
      sources = opt[:arguments] || []
      sources.unshift $stdin.read if opt[:stdin]
      sources
    end

    def safe_run(name, opts)
      begin
        coloring_was             = Term::ANSIColor.coloring?
        Term::ANSIColor.coloring = ENV['I18N_TASKS_COLOR'] || STDOUT.isatty
        run name, opts
      rescue CommandError => e
        log_error e.message
        exit 78
      ensure
        Term::ANSIColor.coloring = coloring_was
      end
    end

    def run(name, opts)
      if opts.empty?
        log_verbose "run #{name.tr('_', '-')} without arguments"
        send name
      else
        log_verbose "run #{name.tr('_', '-')} with #{opts.map { |k, v| "#{k}=#{v}" } * ' '}"
        send name, opts
      end
    end

    protected

    def terminal_report
      @terminal_report ||= I18n::Tasks::Reports::Terminal.new(i18n)
    end

    def spreadsheet_report
      @spreadsheet_report ||= I18n::Tasks::Reports::Spreadsheet.new(i18n)
    end

    class << self
      def run_command(name, opts)
        ::I18n::Tasks::Commands.new.safe_run(name, opts)
      end

      def cmds
        @cmds ||= {}.with_indifferent_access
      end

      def cmd(name, opts)
        cmds[name] = opts
      end
    end

    def desc(name)
      self.class.cmds.try(:[], name).try(:desc)
    end

    def i18n
      @i18n ||= I18n::Tasks::BaseTask.new
    end

    delegate :base_locale, :t, to: :i18n
  end
end
