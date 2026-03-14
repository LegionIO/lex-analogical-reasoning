# frozen_string_literal: true

module Legion
  module Extensions
    module AnalogicalReasoning
      module Helpers
        class AnalogyEngine
          include Constants

          attr_reader :history

          def initialize
            @analogies = {}
            @domains   = Set.new
            @history   = []
          end

          def create_analogy(source_domain:, target_domain:, mappings:, mapping_type:, strength: nil)
            evict_oldest_analogy if @analogies.size >= Constants::MAX_ANALOGIES

            analogy = StructureMap.new(
              source_domain: source_domain,
              target_domain: target_domain,
              mappings:      mappings,
              mapping_type:  mapping_type,
              strength:      strength
            )

            @analogies[analogy.id] = analogy
            register_domain(source_domain)
            register_domain(target_domain)
            record_history(:created, analogy.id)

            analogy
          end

          def find_analogies(domain:)
            @analogies.values.select do |analogy|
              analogy.source_domain == domain || analogy.target_domain == domain
            end
          end

          def apply_analogy(analogy_id:, source_element:)
            analogy = @analogies[analogy_id]
            return { found: false } unless analogy

            target_element = analogy.mappings[source_element]
            return { found: true, mapped: false } unless target_element

            analogy.use!
            record_history(:applied, analogy_id)

            {
              found:          true,
              mapped:         true,
              source_element: source_element,
              target_element: target_element,
              confidence:     analogy.strength,
              analogy_id:     analogy_id
            }
          end

          def evaluate_similarity(source:, target:)
            return 0.0 if source.empty? || target.empty?

            structural = structural_overlap(source, target)
            surface    = surface_overlap(source, target)
            (Constants::STRUCTURAL_WEIGHT * structural) + (Constants::SURFACE_WEIGHT * surface)
          end

          def cross_domain_transfer(analogy_id:, source_knowledge:)
            analogy = @analogies[analogy_id]
            return { transferred: false, reason: :not_found } unless analogy

            transferred = {}
            source_knowledge.each do |key, value|
              mapped_key = analogy.mappings.fetch(key, nil)
              transferred[mapped_key] = value if mapped_key
            end

            analogy.use!
            record_history(:transferred, analogy_id)

            {
              transferred:   true,
              analogy_id:    analogy_id,
              source_domain: analogy.source_domain,
              target_domain: analogy.target_domain,
              result:        transferred,
              coverage:      coverage_ratio(source_knowledge, transferred)
            }
          end

          def reinforce_analogy(analogy_id:, success:)
            analogy = @analogies[analogy_id]
            return { reinforced: false, reason: :not_found } unless analogy

            if success
              analogy.reinforce
              record_history(:reinforced, analogy_id)
            else
              analogy.weaken
              record_history(:weakened, analogy_id)
            end

            { reinforced: true, analogy_id: analogy_id, strength: analogy.strength, state: analogy.state }
          end

          def productive_analogies
            @analogies.values.select(&:productive?)
          end

          def by_domain(domain:)
            find_analogies(domain: domain)
          end

          def by_type(type:)
            @analogies.values.select { |analogy| analogy.mapping_type == type }
          end

          def decay_all
            @analogies.each_value(&:decay)
          end

          def prune_stale
            stale_ids = @analogies.select { |_id, analogy| analogy.state == :stale }.keys
            stale_ids.each { |id| @analogies.delete(id) }
            stale_ids.size
          end

          def to_h
            {
              total_analogies:  @analogies.size,
              total_domains:    @domains.size,
              productive_count: productive_analogies.size,
              history_count:    @history.size,
              domains:          @domains.to_a,
              analogy_states:   state_counts
            }
          end

          private

          def register_domain(domain)
            @domains.add(domain)
            evict_oldest_domain if @domains.size > Constants::MAX_DOMAINS
          end

          def evict_oldest_analogy
            oldest_id = @analogies.min_by { |_id, analogy| analogy.last_used_at }&.first
            @analogies.delete(oldest_id) if oldest_id
          end

          def evict_oldest_domain
            @domains.delete(@domains.first)
          end

          def record_history(event, analogy_id)
            entry = { event: event, analogy_id: analogy_id, at: Time.now.utc }
            @history << entry
            @history.shift while @history.size > Constants::MAX_HISTORY
          end

          def structural_overlap(source, target)
            source_keys = source.keys.to_set(&:to_s)
            target_keys = target.keys.to_set(&:to_s)
            union = source_keys | target_keys
            return 0.0 if union.empty?

            (source_keys & target_keys).size.to_f / union.size
          end

          def surface_overlap(source, target)
            common = source.keys.to_set(&:to_s) & target.keys.to_set(&:to_s)
            surface_match_ratio(common, source, target)
          end

          def surface_match_ratio(common_keys, source, target)
            return 0.0 if common_keys.empty?

            matches = common_keys.count do |key|
              sym     = key.to_sym
              src_val = source.fetch(sym) { source[key] }
              tgt_val = target.fetch(sym) { target[key] }
              src_val == tgt_val && !src_val.nil?
            end
            matches.to_f / common_keys.size
          end

          def coverage_ratio(source_knowledge, transferred)
            return 0.0 if source_knowledge.empty?

            transferred.size.to_f / source_knowledge.size
          end

          def state_counts
            @analogies.values.each_with_object(Hash.new(0)) do |analogy, counts|
              counts[analogy.state] += 1
            end
          end
        end
      end
    end
  end
end
