require 'spec_helper'

describe 'Tree commands' do
  delegate :run_cmd, to: :TestCodebase
  before do
    TestCodebase.setup
  end

  after do
    TestCodebase.teardown
  end

  context 'tree-merge' do
    trees = [{'a' => '1', 'b' => '2'}, {'a' => '-1', 'c' => '3'}]
    it trees.map(&:to_json).join(', ') do
      merged = JSON.parse run_cmd(:tree_merge, format: 'json', arguments: trees.map(&:to_json))
      expect(merged).to eq trees.reduce(:merge)
    end
  end

  context 'tree-select-by-key' do
    forest  = {'a' => '1', 'b' => '2', 'c' => {'a' => '3'}}
    pattern = '{a,c.*}'
    it "-p #{pattern.inspect} #{forest.to_json}" do
      selected = JSON.parse run_cmd(:tree_select_by_key, format: 'json', pattern: pattern, arguments: [forest.to_json])
      expect(selected).to eq(forest.except('b'))
    end
  end

  context 'tree-subtract-by-key' do
    trees = [{'a' => '1', 'b' => '2'}, {'a' => '-1', 'c' => '3'}]
    it trees.map(&:to_json).join(', ') do
      subtracted = JSON.parse run_cmd(:tree_subtract_by_key, format: 'json', arguments: trees.map(&:to_json))
      expect(subtracted).to eq('b' => '2')
    end
  end

  context 'tree-rename-key' do
    def forest
      {'a' => {'b' => {'a' => '1'}}}
    end

    it 'renames root node' do
      renamed = JSON.parse run_cmd(:tree_rename_key, key: 'a', name: 'x', format: 'json', arguments: [forest.to_json])
      expect(renamed).to eq(forest.tap { |f| f['x'] = f.delete('a') })
    end
    it 'renames node' do
      renamed = JSON.parse run_cmd(:tree_rename_key, key: 'a.b', name: 'x', format: 'json', arguments: [forest.to_json])
      expect(renamed).to eq(forest.tap { |f| f['a']['x'] = f['a'].delete('b') })
    end
    it 'renames leaf' do
      renamed = JSON.parse run_cmd(:tree_rename_key, key: 'a.b.a', name: 'x', format: 'json', arguments: [forest.to_json])
      expect(renamed).to eq(forest.tap { |f| f['a']['b']['x'] = f['a']['b'].delete('a') })
    end
  end
end
