# frozen_string_literal: true

require_relative 'lib/legion/extensions/analogical_reasoning/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-analogical-reasoning'
  spec.version       = Legion::Extensions::AnalogicalReasoning::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Analogical Reasoning'
  spec.description   = 'Analogical reasoning engine (Gentner structure mapping, Hofstadter, ' \
                       'Holyoak multi-constraint) for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-analogical-reasoning'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-analogical-reasoning'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-analogical-reasoning'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-analogical-reasoning'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-analogical-reasoning/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-analogical-reasoning.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
