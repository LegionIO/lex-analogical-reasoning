# frozen_string_literal: true

module Legion
  module Extensions
    module AnalogicalReasoning
      module Runners
        module AnalogicalReasoning
          def create_analogy(source_domain:, target_domain:, mappings:, mapping_type: :relational, strength: nil, **)
            unless Helpers::Constants::MAPPING_TYPES.include?(mapping_type)
              return { success: false, error: :invalid_mapping_type,
                       valid_types: Helpers::Constants::MAPPING_TYPES }
            end

            analogy = engine.create_analogy(
              source_domain: source_domain,
              target_domain: target_domain,
              mappings:      mappings,
              mapping_type:  mapping_type,
              strength:      strength
            )

            Legion::Logging.debug "[analogical_reasoning] created analogy id=#{analogy.id[0..7]} " \
                                  "#{source_domain}->#{target_domain} type=#{mapping_type}"

            { success: true, analogy_id: analogy.id, source_domain: source_domain,
              target_domain: target_domain, mapping_type: mapping_type,
              strength: analogy.strength, state: analogy.state }
          end

          def find_analogies(domain:, **)
            analogies = engine.find_analogies(domain: domain)
            Legion::Logging.debug "[analogical_reasoning] find domain=#{domain} count=#{analogies.size}"
            { success: true, domain: domain, analogies: analogies.map(&:to_h), count: analogies.size }
          end

          def apply_analogy(analogy_id:, source_element:, **)
            result = engine.apply_analogy(analogy_id: analogy_id, source_element: source_element)

            Legion::Logging.debug "[analogical_reasoning] apply id=#{analogy_id[0..7]} " \
                                  "element=#{source_element} mapped=#{result[:mapped]}"

            { success: true }.merge(result)
          end

          def evaluate_similarity(source:, target:, **)
            score = engine.evaluate_similarity(source: source, target: target)
            above_threshold = score >= Helpers::Constants::SIMILARITY_THRESHOLD

            Legion::Logging.debug "[analogical_reasoning] similarity=#{score.round(3)} " \
                                  "above_threshold=#{above_threshold}"

            { success: true, similarity_score: score, above_threshold: above_threshold,
              threshold: Helpers::Constants::SIMILARITY_THRESHOLD }
          end

          def cross_domain_transfer(analogy_id:, source_knowledge:, **)
            result = engine.cross_domain_transfer(analogy_id: analogy_id, source_knowledge: source_knowledge)

            Legion::Logging.debug "[analogical_reasoning] transfer id=#{analogy_id[0..7]} " \
                                  "transferred=#{result[:transferred]} coverage=#{result[:coverage]&.round(2)}"

            { success: true }.merge(result)
          end

          def reinforce_analogy(analogy_id:, success:, **)
            result = engine.reinforce_analogy(analogy_id: analogy_id, success: success)

            Legion::Logging.debug "[analogical_reasoning] reinforce id=#{analogy_id[0..7]} " \
                                  "success=#{success} new_state=#{result[:state]}"

            { success: true }.merge(result)
          end

          def productive_analogies(**)
            analogies = engine.productive_analogies
            Legion::Logging.debug "[analogical_reasoning] productive count=#{analogies.size}"
            { success: true, analogies: analogies.map(&:to_h), count: analogies.size }
          end

          def update_analogical_reasoning(**)
            engine.decay_all
            pruned = engine.prune_stale
            Legion::Logging.debug "[analogical_reasoning] decay+prune pruned=#{pruned}"
            { success: true, pruned: pruned }
          end

          def analogical_reasoning_stats(**)
            stats = engine.to_h
            Legion::Logging.debug "[analogical_reasoning] stats total=#{stats[:total_analogies]}"
            { success: true }.merge(stats)
          end

          private

          def engine
            @engine ||= Helpers::AnalogyEngine.new
          end
        end
      end
    end
  end
end
