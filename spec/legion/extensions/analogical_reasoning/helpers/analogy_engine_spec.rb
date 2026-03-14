# frozen_string_literal: true

require 'legion/extensions/analogical_reasoning/helpers/analogy_engine'

RSpec.describe Legion::Extensions::AnalogicalReasoning::Helpers::AnalogyEngine do
  subject(:engine) { described_class.new }

  let(:base_analogy_params) do
    {
      source_domain: :solar_system,
      target_domain: :atom,
      mappings:      { sun: :nucleus, planet: :electron },
      mapping_type:  :relational
    }
  end

  describe '#create_analogy' do
    it 'creates and returns a StructureMap' do
      analogy = engine.create_analogy(**base_analogy_params)
      expect(analogy).to be_a(Legion::Extensions::AnalogicalReasoning::Helpers::StructureMap)
    end

    it 'assigns correct domains' do
      analogy = engine.create_analogy(**base_analogy_params)
      expect(analogy.source_domain).to eq(:solar_system)
      expect(analogy.target_domain).to eq(:atom)
    end

    it 'records the analogy in history' do
      engine.create_analogy(**base_analogy_params)
      expect(engine.history.last[:event]).to eq(:created)
    end

    it 'stores the analogy for retrieval' do
      analogy = engine.create_analogy(**base_analogy_params)
      result = engine.apply_analogy(analogy_id: analogy.id, source_element: :sun)
      expect(result[:found]).to be true
    end
  end

  describe '#find_analogies' do
    it 'finds analogies by source domain' do
      engine.create_analogy(**base_analogy_params)
      results = engine.find_analogies(domain: :solar_system)
      expect(results.size).to eq(1)
    end

    it 'finds analogies by target domain' do
      engine.create_analogy(**base_analogy_params)
      results = engine.find_analogies(domain: :atom)
      expect(results.size).to eq(1)
    end

    it 'returns empty array when domain not found' do
      results = engine.find_analogies(domain: :unknown)
      expect(results).to be_empty
    end

    it 'finds across multiple analogies' do
      engine.create_analogy(**base_analogy_params)
      engine.create_analogy(
        source_domain: :solar_system,
        target_domain: :family,
        mappings:      { sun: :parent },
        mapping_type:  :relational
      )
      results = engine.find_analogies(domain: :solar_system)
      expect(results.size).to eq(2)
    end
  end

  describe '#apply_analogy' do
    let(:analogy) { engine.create_analogy(**base_analogy_params) }

    it 'returns mapped element when found' do
      result = engine.apply_analogy(analogy_id: analogy.id, source_element: :sun)
      expect(result[:found]).to be true
      expect(result[:mapped]).to be true
      expect(result[:target_element]).to eq(:nucleus)
    end

    it 'returns mapped: false when source element has no mapping' do
      result = engine.apply_analogy(analogy_id: analogy.id, source_element: :comet)
      expect(result[:found]).to be true
      expect(result[:mapped]).to be false
    end

    it 'returns found: false for unknown analogy_id' do
      result = engine.apply_analogy(analogy_id: 'nonexistent', source_element: :sun)
      expect(result[:found]).to be false
    end

    it 'includes confidence in result' do
      result = engine.apply_analogy(analogy_id: analogy.id, source_element: :sun)
      expect(result[:confidence]).to be_a(Float)
    end

    it 'records apply event in history' do
      engine.apply_analogy(analogy_id: analogy.id, source_element: :sun)
      applied = engine.history.select { |h| h[:event] == :applied }
      expect(applied).not_to be_empty
    end
  end

  describe '#evaluate_similarity' do
    it 'returns 1.0 for identical concept hashes' do
      concept = { color: :red, shape: :round }
      score = engine.evaluate_similarity(source: concept, target: concept)
      expect(score).to be > 0.8
    end

    it 'returns 0.0 for empty hashes' do
      expect(engine.evaluate_similarity(source: {}, target: {})).to eq(0.0)
    end

    it 'returns lower score for dissimilar concepts' do
      source = { color: :red, shape: :round, size: :large }
      target = { color: :blue, shape: :square, weight: :heavy }
      score = engine.evaluate_similarity(source: source, target: target)
      expect(score).to be < 0.5
    end

    it 'returns higher score for structurally similar concepts' do
      source = { role: :attractor, relation: :orbits, parent: :center }
      target = { role: :attractor, relation: :orbits, parent: :core }
      score = engine.evaluate_similarity(source: source, target: target)
      expect(score).to be > 0.4
    end
  end

  describe '#cross_domain_transfer' do
    let(:analogy) { engine.create_analogy(**base_analogy_params) }

    it 'maps source knowledge to target domain' do
      result = engine.cross_domain_transfer(
        analogy_id:       analogy.id,
        source_knowledge: { sun: 'massive gravity well' }
      )
      expect(result[:transferred]).to be true
      expect(result[:result][:nucleus]).to eq('massive gravity well')
    end

    it 'returns transferred: false for unknown analogy' do
      result = engine.cross_domain_transfer(analogy_id: 'nope', source_knowledge: {})
      expect(result[:transferred]).to be false
    end

    it 'includes coverage ratio' do
      result = engine.cross_domain_transfer(
        analogy_id:       analogy.id,
        source_knowledge: { sun: 'center', comet: 'visitor' }
      )
      expect(result[:coverage]).to eq(0.5)
    end

    it 'records transfer event in history' do
      engine.cross_domain_transfer(analogy_id: analogy.id, source_knowledge: { sun: 'data' })
      transferred = engine.history.select { |h| h[:event] == :transferred }
      expect(transferred).not_to be_empty
    end
  end

  describe '#reinforce_analogy' do
    let(:analogy) { engine.create_analogy(**base_analogy_params) }

    it 'strengthens analogy on success' do
      initial = analogy.strength
      engine.reinforce_analogy(analogy_id: analogy.id, success: true)
      expect(analogy.strength).to be > initial
    end

    it 'weakens analogy on failure' do
      initial = analogy.strength
      engine.reinforce_analogy(analogy_id: analogy.id, success: false)
      expect(analogy.strength).to be < initial
    end

    it 'returns not_found for unknown analogy' do
      result = engine.reinforce_analogy(analogy_id: 'nope', success: true)
      expect(result[:reinforced]).to be false
    end

    it 'returns reinforced: true on success' do
      result = engine.reinforce_analogy(analogy_id: analogy.id, success: true)
      expect(result[:reinforced]).to be true
    end
  end

  describe '#productive_analogies' do
    it 'returns only productive analogies' do
      strong_analogy = engine.create_analogy(
        source_domain: :water,
        target_domain: :electricity,
        mappings:      { pressure: :voltage },
        mapping_type:  :relational,
        strength:      0.9
      )
      engine.create_analogy(**base_analogy_params)
      productive = engine.productive_analogies
      expect(productive.map(&:id)).to include(strong_analogy.id)
    end

    it 'returns empty array when no productive analogies' do
      engine.create_analogy(**base_analogy_params)
      expect(engine.productive_analogies).to be_empty
    end
  end

  describe '#by_domain' do
    it 'delegates to find_analogies' do
      engine.create_analogy(**base_analogy_params)
      results = engine.by_domain(domain: :solar_system)
      expect(results.size).to eq(1)
    end
  end

  describe '#by_type' do
    it 'filters analogies by mapping type' do
      engine.create_analogy(**base_analogy_params)
      engine.create_analogy(
        source_domain: :water,
        target_domain: :electricity,
        mappings:      { pressure: :voltage },
        mapping_type:  :attribute
      )
      results = engine.by_type(type: :relational)
      expect(results.all? { |analogy| analogy.mapping_type == :relational }).to be true
    end
  end

  describe '#decay_all' do
    it 'reduces strength of all analogies' do
      analogy = engine.create_analogy(**base_analogy_params)
      initial = analogy.strength
      engine.decay_all
      expect(analogy.strength).to be < initial
    end
  end

  describe '#prune_stale' do
    it 'removes stale analogies and returns count' do
      engine.create_analogy(
        source_domain: :old, target_domain: :domain, mappings: {}, mapping_type: :attribute,
        strength: 0.06
      )
      engine.create_analogy(**base_analogy_params)

      pruned = engine.prune_stale
      expect(pruned).to eq(1)
      expect(engine.find_analogies(domain: :old)).to be_empty
    end

    it 'returns 0 when no stale analogies' do
      engine.create_analogy(**base_analogy_params, strength: 0.9)
      expect(engine.prune_stale).to eq(0)
    end
  end

  describe '#to_h' do
    it 'returns stats hash with expected keys' do
      engine.create_analogy(**base_analogy_params)
      stats = engine.to_h
      expect(stats).to have_key(:total_analogies)
      expect(stats).to have_key(:total_domains)
      expect(stats).to have_key(:productive_count)
      expect(stats).to have_key(:history_count)
      expect(stats).to have_key(:domains)
      expect(stats).to have_key(:analogy_states)
    end

    it 'counts domains correctly' do
      engine.create_analogy(**base_analogy_params)
      expect(engine.to_h[:total_domains]).to eq(2)
    end
  end
end
