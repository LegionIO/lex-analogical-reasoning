# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module AnalogicalReasoning
      module Helpers
        class StructureMap
          include Constants

          attr_reader :id, :source_domain, :target_domain, :mappings, :mapping_type, :times_used, :created_at,
                      :last_used_at, :strength

          def initialize(source_domain:, target_domain:, mappings:, mapping_type:, strength: nil)
            @id            = SecureRandom.uuid
            @source_domain = source_domain
            @target_domain = target_domain
            @mappings      = mappings
            @mapping_type  = mapping_type
            @strength      = (strength || Constants::DEFAULT_STRENGTH).clamp(
              Constants::STRENGTH_FLOOR,
              Constants::STRENGTH_CEILING
            )
            @times_used    = 0
            @created_at    = Time.now.utc
            @last_used_at  = Time.now.utc
          end

          def structural_score
            return 0.0 if mappings.empty?

            relational_count = mappings.count { |_src, tgt| tgt.is_a?(Hash) && tgt[:type] == :relational }
            relational_count.to_f / mappings.size
          end

          def surface_score
            return 0.0 if mappings.empty?

            attribute_count = mappings.count { |_src, tgt| !(tgt.is_a?(Hash) && tgt[:type] == :relational) }
            attribute_count.to_f / mappings.size
          end

          def similarity_score
            (Constants::STRUCTURAL_WEIGHT * structural_score) +
              (Constants::SURFACE_WEIGHT * surface_score)
          end

          def use!
            @times_used   += 1
            @last_used_at  = Time.now.utc
            reinforce(amount: Constants::REINFORCEMENT_RATE * 0.5)
            self
          end

          def reinforce(amount: Constants::REINFORCEMENT_RATE)
            @strength = (@strength + amount).clamp(Constants::STRENGTH_FLOOR, Constants::STRENGTH_CEILING)
            self
          end

          def weaken(amount: Constants::REINFORCEMENT_RATE)
            @strength = (@strength - amount).clamp(Constants::STRENGTH_FLOOR, Constants::STRENGTH_CEILING)
            self
          end

          def decay
            @strength = (@strength - Constants::DECAY_RATE).clamp(Constants::STRENGTH_FLOOR, Constants::STRENGTH_CEILING)
            self
          end

          def state
            thresholds = Constants::STATE_THRESHOLDS
            if @strength >= thresholds[:productive]
              :productive
            elsif @strength >= thresholds[:validated]
              :validated
            elsif @strength >= thresholds[:candidate]
              :candidate
            else
              :stale
            end
          end

          def productive?
            state == :productive
          end

          def to_h
            {
              id:               @id,
              source_domain:    @source_domain,
              target_domain:    @target_domain,
              mappings:         @mappings,
              mapping_type:     @mapping_type,
              strength:         @strength,
              structural_score: structural_score,
              surface_score:    surface_score,
              similarity_score: similarity_score,
              state:            state,
              times_used:       @times_used,
              created_at:       @created_at,
              last_used_at:     @last_used_at
            }
          end
        end
      end
    end
  end
end
