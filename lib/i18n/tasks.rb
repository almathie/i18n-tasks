# coding: utf-8
# define all the modules to be able to use ::
module I18n
  module Tasks
    module Data
    end
  end
end


require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/object/blank'
require 'term/ansicolor'
require 'erubis'

require 'i18n/tasks/version'
require 'i18n/tasks/base_task'

