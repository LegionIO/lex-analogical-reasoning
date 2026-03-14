# frozen_string_literal: true

require 'legion/extensions/analogical_reasoning/client'

RSpec.describe Legion::Extensions::AnalogicalReasoning::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:create_analogy)
    expect(client).to respond_to(:find_analogies)
    expect(client).to respond_to(:apply_analogy)
    expect(client).to respond_to(:evaluate_similarity)
    expect(client).to respond_to(:cross_domain_transfer)
    expect(client).to respond_to(:reinforce_analogy)
    expect(client).to respond_to(:productive_analogies)
    expect(client).to respond_to(:update_analogical_reasoning)
    expect(client).to respond_to(:analogical_reasoning_stats)
  end

  it 'accepts an injected engine' do
    custom_engine = Legion::Extensions::AnalogicalReasoning::Helpers::AnalogyEngine.new
    client = described_class.new(engine: custom_engine)
    expect(client).to be_a(described_class)
  end

  it 'creates a default engine when none provided' do
    client = described_class.new
    result = client.analogical_reasoning_stats
    expect(result[:success]).to be true
    expect(result[:total_analogies]).to eq(0)
  end
end
