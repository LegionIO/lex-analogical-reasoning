# frozen_string_literal: true

require 'legion/extensions/analogical_reasoning/version'
require 'legion/extensions/analogical_reasoning/helpers/constants'
require 'legion/extensions/analogical_reasoning/helpers/structure_map'
require 'legion/extensions/analogical_reasoning/helpers/analogy_engine'
require 'legion/extensions/analogical_reasoning/runners/analogical_reasoning'
require 'legion/extensions/analogical_reasoning/client'

module Legion
  module Extensions
    module AnalogicalReasoning
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
