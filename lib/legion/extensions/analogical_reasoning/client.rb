# frozen_string_literal: true

require 'legion/extensions/analogical_reasoning/helpers/constants'
require 'legion/extensions/analogical_reasoning/helpers/structure_map'
require 'legion/extensions/analogical_reasoning/helpers/analogy_engine'
require 'legion/extensions/analogical_reasoning/runners/analogical_reasoning'

module Legion
  module Extensions
    module AnalogicalReasoning
      class Client
        include Runners::AnalogicalReasoning

        def initialize(engine: nil, **)
          @engine = engine || Helpers::AnalogyEngine.new
        end

        private

        attr_reader :engine
      end
    end
  end
end
