# coding: utf-8
require 'set'
module I18n::Tasks::PluralKeys
  PLURAL_KEY_SUFFIXES = Set.new %w(zero one two few many other)
  PLURAL_KEY_RE = /\.(?:#{PLURAL_KEY_SUFFIXES.to_a * '|'})$/

  def collapse_plural_nodes!(tree)
    tree.leaves.map(&:parent).uniq.each do |node|
      children = node.children
      if children.present? && children.all? { |c| PLURAL_KEY_SUFFIXES.include?(c.key) }
        node.value    = children.to_hash
        node.data.merge!(children.first.data)
        node.children = nil
      end
    end
    tree
  end

  # @param [String] key i18n key
  # @param [String] locale to pull key data from
  # @return the base form if the key is a specific plural form (e.g. apple for apple.many), and the key as passed otherwise
  def depluralize_key(key, locale = base_locale)
    return key if key !~ PLURAL_KEY_RE
    parent_key = split_key(key)[0..-2] * '.'
    nodes = tree("#{locale}.#{parent_key}").presence || (locale != base_locale && tree("#{base_locale}.#{parent_key}"))
    if nodes && nodes.all? { |x| x.leaf? && ".#{x.key}" =~ PLURAL_KEY_RE }
      parent_key
    else
      key
    end
  end
end
