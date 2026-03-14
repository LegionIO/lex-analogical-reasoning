# frozen_string_literal: true

require 'legion/extensions/analogical_reasoning/client'

RSpec.describe Legion::Extensions::AnalogicalReasoning::Runners::AnalogicalReasoning do
  let(:client) { Legion::Extensions::AnalogicalReasoning::Client.new }

  let(:base_params) do
    {
      source_domain: :solar_system,
      target_domain: :atom,
      mappings:      { sun: :nucleus, planet: :electron },
      mapping_type:  :relational
    }
  end

  describe '#create_analogy' do
    it 'creates an analogy and returns success hash' do
      result = client.create_analogy(**base_params)
      expect(result[:success]).to be true
      expect(result[:analogy_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:source_domain]).to eq(:solar_system)
      expect(result[:target_domain]).to eq(:atom)
    end

    it 'defaults mapping_type to relational' do
      result = client.create_analogy(
        source_domain: :water,
        target_domain: :electricity,
        mappings:      { pressure: :voltage }
      )
      expect(result[:success]).to be true
      expect(result[:mapping_type]).to eq(:relational)
    end

    it 'rejects invalid mapping type' do
      result = client.create_analogy(
        source_domain: :a, target_domain: :b, mappings: {}, mapping_type: :nonexistent
      )
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_mapping_type)
    end

    it 'accepts all valid mapping types' do
      %i[attribute relational system].each do |type|
        result = client.create_analogy(
          source_domain: :src, target_domain: :tgt, mappings: {}, mapping_type: type
        )
        expect(result[:success]).to be true
      end
    end

    it 'includes state in result' do
      result = client.create_analogy(**base_params)
      expect(Legion::Extensions::AnalogicalReasoning::Helpers::Constants::ANALOGY_STATES)
        .to include(result[:state])
    end
  end

  describe '#find_analogies' do
    it 'finds analogies by domain' do
      client.create_analogy(**base_params)
      result = client.find_analogies(domain: :solar_system)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:analogies]).to be_an(Array)
    end

    it 'returns empty when domain not found' do
      result = client.find_analogies(domain: :unknown)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end
  end

  describe '#apply_analogy' do
    let(:analogy_id) do
      client.create_analogy(**base_params)[:analogy_id]
    end

    it 'applies mapping successfully' do
      result = client.apply_analogy(analogy_id: analogy_id, source_element: :sun)
      expect(result[:success]).to be true
      expect(result[:mapped]).to be true
      expect(result[:target_element]).to eq(:nucleus)
    end

    it 'returns success: true with mapped: false for unknown element' do
      result = client.apply_analogy(analogy_id: analogy_id, source_element: :asteroid)
      expect(result[:success]).to be true
      expect(result[:mapped]).to be false
    end

    it 'returns found: false for unknown analogy_id' do
      result = client.apply_analogy(analogy_id: 'nope', source_element: :sun)
      expect(result[:success]).to be true
      expect(result[:found]).to be false
    end
  end

  describe '#evaluate_similarity' do
    it 'returns a similarity score' do
      result = client.evaluate_similarity(
        source: { role: :center, relation: :attracts },
        target: { role: :center, relation: :attracts }
      )
      expect(result[:success]).to be true
      expect(result[:similarity_score]).to be_a(Float)
    end

    it 'indicates when score is above threshold' do
      result = client.evaluate_similarity(
        source: { role: :center, relation: :attracts, type: :massive },
        target: { role: :center, relation: :attracts, type: :massive }
      )
      expect(result[:above_threshold]).to be true
    end

    it 'indicates when score is below threshold' do
      result = client.evaluate_similarity(
        source: { alpha: :one },
        target: { beta: :two }
      )
      expect(result[:above_threshold]).to be false
    end

    it 'includes threshold in result' do
      result = client.evaluate_similarity(source: {}, target: {})
      expect(result[:threshold]).to eq(Legion::Extensions::AnalogicalReasoning::Helpers::Constants::SIMILARITY_THRESHOLD)
    end
  end

  describe '#cross_domain_transfer' do
    let(:analogy_id) { client.create_analogy(**base_params)[:analogy_id] }

    it 'transfers knowledge across domains' do
      result = client.cross_domain_transfer(
        analogy_id:       analogy_id,
        source_knowledge: { sun: 'gravitational center' }
      )
      expect(result[:success]).to be true
      expect(result[:transferred]).to be true
      expect(result[:result][:nucleus]).to eq('gravitational center')
    end

    it 'returns success with transferred: false for unknown analogy' do
      result = client.cross_domain_transfer(analogy_id: 'nope', source_knowledge: {})
      expect(result[:success]).to be true
      expect(result[:transferred]).to be false
    end
  end

  describe '#reinforce_analogy' do
    let(:analogy_id) { client.create_analogy(**base_params)[:analogy_id] }

    it 'reinforces on success' do
      result = client.reinforce_analogy(analogy_id: analogy_id, success: true)
      expect(result[:success]).to be true
      expect(result[:reinforced]).to be true
      expect(result[:strength]).to be_a(Float)
    end

    it 'weakens on failure' do
      create_result = client.create_analogy(**base_params)
      initial_strength = create_result[:strength]
      client.reinforce_analogy(analogy_id: create_result[:analogy_id], success: false)
      find_result = client.find_analogies(domain: :solar_system)
      final_strength = find_result[:analogies].first[:strength]
      expect(final_strength).to be < initial_strength
    end

    it 'returns not_found for unknown analogy' do
      result = client.reinforce_analogy(analogy_id: 'nope', success: true)
      expect(result[:success]).to be true
      expect(result[:reinforced]).to be false
    end
  end

  describe '#productive_analogies' do
    it 'returns only productive analogies' do
      client.create_analogy(**base_params, strength: 0.9)
      result = client.productive_analogies
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end

    it 'returns empty when no productive analogies' do
      client.create_analogy(**base_params)
      result = client.productive_analogies
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end
  end

  describe '#update_analogical_reasoning' do
    it 'performs decay and pruning' do
      client.create_analogy(**base_params)
      result = client.update_analogical_reasoning
      expect(result[:success]).to be true
      expect(result[:pruned]).to be_a(Integer)
    end
  end

  describe '#analogical_reasoning_stats' do
    it 'returns stats hash' do
      client.create_analogy(**base_params)
      result = client.analogical_reasoning_stats
      expect(result[:success]).to be true
      expect(result[:total_analogies]).to eq(1)
      expect(result[:total_domains]).to eq(2)
    end
  end
end
