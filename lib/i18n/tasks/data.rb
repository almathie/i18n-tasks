# coding: utf-8
require 'i18n/tasks/data/file_system'

module I18n::Tasks
  module Data

    # I18n data provider
    # @see I18n::Tasks::Data::FileSystem
    def data
      @data ||= begin
        conf    = (config[:data] || {}).with_indifferent_access
        adapter = (conf[:adapter].presence || conf[:class].presence || :file_system).to_s
        adapter = "I18n::Tasks::Data::#{adapter.camelize}" if adapter !~ /[A-Z]/
        conf = conf.except(:adapter, :class).merge(
            base_locale: base_locale,
            locales:     (normalize_locales(config[:locales]) if config[:locales].present?)
        )
        adapter.constantize.new conf
      end
    end

    def data_forest(locales = self.locales)
      locales.inject(Tree::Siblings.new) do |tree, locale|
        tree.merge! data[locale]
      end
    end

    def t(key, locale = base_locale)
      data.t(key, locale)
    end

    def tree(sel)
      data[split_key(sel, 2).first][sel].try(:children)
    end

    def node(key, locale = base_locale)
      data[locale]["#{locale}.#{key}"]
    end

    def build_tree(hash)
      I18n::Tasks::Data::Tree::Siblings.from_nested_hash(hash)
    end

    def t_proc(locale = base_locale)
      @t_proc         ||= {}
      @t_proc[locale] ||= proc { |key| t(key, locale) }
    end

    # whether the value for key exists in locale (defaults: base_locale)
    def key_value?(key, locale = base_locale)
      !t(key, locale).nil?
    end

    # write to store, normalizing all data
    def normalize_store!(from = nil, pattern_router = false)
      from   = self.locales unless from
      router = pattern_router ? ::I18n::Tasks::Data::Router::PatternRouter.new(data, data.config) : data.router
      data.with_router(router) do
        Array(from).each do |target_locale|
          # store handles normalization
          data[target_locale] = data[target_locale]
        end
      end
    end
  end
end
