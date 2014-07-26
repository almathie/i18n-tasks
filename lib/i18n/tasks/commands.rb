# coding: utf-8
require 'i18n/tasks/command/commander'
require 'i18n/tasks/command/options/shared'
require 'i18n/tasks/command/options/locales'
require 'i18n/tasks/command/options/trees'
require 'i18n/tasks/command/commands/missing'
require 'i18n/tasks/command/commands/usages'
require 'i18n/tasks/command/commands/eq_base'
require 'i18n/tasks/command/commands/data'
require 'i18n/tasks/command/commands/tree'
require 'i18n/tasks/command/commands/meta'
require 'i18n/tasks/reports/terminal'
require 'i18n/tasks/reports/spreadsheet'

module I18n::Tasks
  class Commands < Command::Commander
    include Term::ANSIColor
    require 'highline/import'
    include Command::Options::Shared
    include Command::Options::Locales
    include Command::Options::Trees

    include Command::Commands::Missing
    include Command::Commands::Usages
    include Command::Commands::EqBase
    include Command::Commands::Data
    include Command::Commands::Tree
    include Command::Commands::Meta

    cmd :xlsx_report,
        args: '[locale...]',
        desc: 'save missing and unused translations to an Excel file',
        opt:  [cmd_opt(:locales),
               {short: :p, long: :path=, desc: 'Destination path', conf: {default: 'tmp/i18n-report.xlsx'}}]

    def xlsx_report(opt = {})
      begin
        require 'axlsx'
      rescue LoadError
        message = %Q(For spreadsheet report please add axlsx gem to Gemfile:\ngem 'axlsx', '~> 2.0')
        log_stderr Term::ANSIColor.red Term::ANSIColor.bold message
        exit 1
      end
      opt_locales! opt
      spreadsheet_report.save_report opt[:path], opt.except(:path)
    end
  end
end
