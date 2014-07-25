require 'spec_helper'

describe 'Data commands' do
  delegate :run_cmd, to: :TestCodebase
  def en_data
    {'en' => {'common' => {'hello' => 'Hello'}}}
  end

  def en_data_2
    {'en' => {'common' => {'hi' => 'Hi'}}}
  end


  before do
    TestCodebase.setup('config/locales/en.yml' => en_data.to_yaml)
  end

  after do
    TestCodebase.teardown
  end

  it '#data' do
    expect(JSON.parse(run_cmd :data, format: 'json')).to eq(en_data)
  end

  it '#data-merge' do
    expect(JSON.parse(run_cmd :data_merge, format: 'json', arguments: [en_data_2.to_json])).to eq(en_data.deep_merge en_data_2)
  end

  it '#data-write' do
    expect(JSON.parse(run_cmd :data_write, format: 'json', arguments: [en_data_2.to_json])).to eq(en_data_2)
  end
end
