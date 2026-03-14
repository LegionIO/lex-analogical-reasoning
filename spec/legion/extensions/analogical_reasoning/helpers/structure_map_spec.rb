# frozen_string_literal: true

require 'legion/extensions/analogical_reasoning/helpers/structure_map'

RSpec.describe Legion::Extensions::AnalogicalReasoning::Helpers::StructureMap do
  let(:relational_mappings) do
    {
      sun:   { type: :relational, maps_to: :nucleus },
      orbit: { type: :relational, maps_to: :electron_path }
    }
  end

  let(:surface_mappings) do
    {
      yellow: :gold,
      hot:    :energetic
    }
  end

  let(:structure_map) do
    described_class.new(
      source_domain: :solar_system,
      target_domain: :atom,
      mappings:      relational_mappings,
      mapping_type:  :relational
    )
  end

  describe '#initialize' do
    it 'assigns required attributes' do
      expect(structure_map.source_domain).to eq(:solar_system)
      expect(structure_map.target_domain).to eq(:atom)
      expect(structure_map.mapping_type).to eq(:relational)
      expect(structure_map.mappings).to eq(relational_mappings)
    end

    it 'generates a UUID id' do
      expect(structure_map.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets default strength' do
      expect(structure_map.strength).to eq(Legion::Extensions::AnalogicalReasoning::Helpers::Constants::DEFAULT_STRENGTH)
    end

    it 'clamps custom strength to ceiling' do
      map = described_class.new(
        source_domain: :a,
        target_domain: :b,
        mappings:      {},
        mapping_type:  :attribute,
        strength:      2.0
      )
      expect(map.strength).to eq(Legion::Extensions::AnalogicalReasoning::Helpers::Constants::STRENGTH_CEILING)
    end

    it 'clamps custom strength to floor' do
      map = described_class.new(
        source_domain: :a,
        target_domain: :b,
        mappings:      {},
        mapping_type:  :attribute,
        strength:      0.0
      )
      expect(map.strength).to eq(Legion::Extensions::AnalogicalReasoning::Helpers::Constants::STRENGTH_FLOOR)
    end

    it 'sets times_used to 0' do
      expect(structure_map.times_used).to eq(0)
    end
  end

  describe '#structural_score' do
    it 'returns proportion of relational mappings' do
      expect(structure_map.structural_score).to eq(1.0)
    end

    it 'returns 0.0 for empty mappings' do
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: {}, mapping_type: :attribute
      )
      expect(map.structural_score).to eq(0.0)
    end

    it 'returns partial score for mixed mappings' do
      mixed = relational_mappings.merge(surface_mappings)
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: mixed, mapping_type: :relational
      )
      expect(map.structural_score).to eq(0.5)
    end
  end

  describe '#surface_score' do
    it 'returns proportion of non-relational mappings' do
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: surface_mappings, mapping_type: :attribute
      )
      expect(map.surface_score).to eq(1.0)
    end

    it 'returns 0.0 for empty mappings' do
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: {}, mapping_type: :attribute
      )
      expect(map.surface_score).to eq(0.0)
    end
  end

  describe '#similarity_score' do
    it 'weights structural and surface scores correctly' do
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: relational_mappings, mapping_type: :relational
      )
      expected = (0.7 * 1.0) + (0.3 * 0.0)
      expect(map.similarity_score).to be_within(0.001).of(expected)
    end
  end

  describe '#use!' do
    it 'increments times_used' do
      structure_map.use!
      expect(structure_map.times_used).to eq(1)
    end

    it 'updates last_used_at' do
      before = structure_map.last_used_at
      sleep 0.01
      structure_map.use!
      expect(structure_map.last_used_at).to be >= before
    end

    it 'boosts strength' do
      initial = structure_map.strength
      structure_map.use!
      expect(structure_map.strength).to be > initial
    end

    it 'returns self' do
      expect(structure_map.use!).to eq(structure_map)
    end
  end

  describe '#reinforce' do
    it 'increases strength by reinforcement rate' do
      initial = structure_map.strength
      structure_map.reinforce
      expect(structure_map.strength).to be_within(0.001).of(
        (initial + Legion::Extensions::AnalogicalReasoning::Helpers::Constants::REINFORCEMENT_RATE)
          .clamp(
            Legion::Extensions::AnalogicalReasoning::Helpers::Constants::STRENGTH_FLOOR,
            Legion::Extensions::AnalogicalReasoning::Helpers::Constants::STRENGTH_CEILING
          )
      )
    end

    it 'does not exceed strength ceiling' do
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: {}, mapping_type: :attribute,
        strength: Legion::Extensions::AnalogicalReasoning::Helpers::Constants::STRENGTH_CEILING
      )
      map.reinforce(amount: 0.5)
      expect(map.strength).to eq(Legion::Extensions::AnalogicalReasoning::Helpers::Constants::STRENGTH_CEILING)
    end
  end

  describe '#weaken' do
    it 'decreases strength' do
      initial = structure_map.strength
      structure_map.weaken
      expect(structure_map.strength).to be < initial
    end

    it 'does not drop below strength floor' do
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: {}, mapping_type: :attribute,
        strength: Legion::Extensions::AnalogicalReasoning::Helpers::Constants::STRENGTH_FLOOR
      )
      map.weaken(amount: 0.5)
      expect(map.strength).to eq(Legion::Extensions::AnalogicalReasoning::Helpers::Constants::STRENGTH_FLOOR)
    end
  end

  describe '#decay' do
    it 'reduces strength by decay rate' do
      initial = structure_map.strength
      structure_map.decay
      expect(structure_map.strength).to be_within(0.001).of(
        (initial - Legion::Extensions::AnalogicalReasoning::Helpers::Constants::DECAY_RATE)
          .clamp(
            Legion::Extensions::AnalogicalReasoning::Helpers::Constants::STRENGTH_FLOOR,
            Legion::Extensions::AnalogicalReasoning::Helpers::Constants::STRENGTH_CEILING
          )
      )
    end
  end

  describe '#state' do
    it 'returns :productive when strength is high' do
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: {}, mapping_type: :attribute, strength: 0.9
      )
      expect(map.state).to eq(:productive)
    end

    it 'returns :validated for mid-range strength' do
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: {}, mapping_type: :attribute, strength: 0.6
      )
      expect(map.state).to eq(:validated)
    end

    it 'returns :candidate for low-mid strength' do
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: {}, mapping_type: :attribute, strength: 0.35
      )
      expect(map.state).to eq(:candidate)
    end

    it 'returns :stale for very low strength' do
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: {}, mapping_type: :attribute, strength: 0.1
      )
      expect(map.state).to eq(:stale)
    end
  end

  describe '#productive?' do
    it 'returns true when state is productive' do
      map = described_class.new(
        source_domain: :a, target_domain: :b, mappings: {}, mapping_type: :attribute, strength: 0.9
      )
      expect(map.productive?).to be true
    end

    it 'returns false when state is not productive' do
      expect(structure_map.productive?).to be false
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      hash = structure_map.to_h
      expected_keys = %i[id source_domain target_domain mappings mapping_type strength
                         structural_score surface_score similarity_score state
                         times_used created_at last_used_at]
      expected_keys.each { |key| expect(hash).to have_key(key) }
    end

    it 'reflects current state' do
      hash = structure_map.to_h
      expect(hash[:source_domain]).to eq(:solar_system)
      expect(hash[:target_domain]).to eq(:atom)
    end
  end
end
