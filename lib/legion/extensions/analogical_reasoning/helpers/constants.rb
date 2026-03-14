# frozen_string_literal: true

module Legion
  module Extensions
    module AnalogicalReasoning
      module Helpers
        module Constants
          MAX_ANALOGIES  = 200
          MAX_DOMAINS    = 50
          MAX_HISTORY    = 300

          SIMILARITY_THRESHOLD = 0.4
          STRUCTURAL_WEIGHT    = 0.7
          SURFACE_WEIGHT       = 0.3

          DEFAULT_STRENGTH    = 0.5
          STRENGTH_FLOOR      = 0.05
          STRENGTH_CEILING    = 0.95

          REINFORCEMENT_RATE = 0.1
          DECAY_RATE         = 0.01

          MAPPING_TYPES   = %i[attribute relational system].freeze
          ANALOGY_STATES  = %i[candidate validated productive stale].freeze
          STATE_THRESHOLDS = {
            productive: 0.75,
            validated:  0.5,
            candidate:  0.25
          }.freeze
        end
      end
    end
  end
end
