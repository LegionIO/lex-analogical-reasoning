# lex-analogical-reasoning

Analogical reasoning engine (Gentner structure mapping, Hofstadter, Holyoak multi-constraint) for brain-modeled agentic AI.

## What It Does

Models the cognitive process of analogical reasoning: finding structural correspondences between domains and using those mappings to transfer knowledge, generate predictions, and solve problems in unfamiliar territory. Based on Gentner's Structure-Mapping Theory, which prioritizes relational structure over surface features. Analogies are tracked with strength scores that evolve through reinforcement and decay.

## Core Concept: Structure Mapping

An analogy is a set of correspondences between a source domain (familiar) and a target domain (new):

```ruby
# Create a structural mapping between two domains
client.create_analogy(
  source_domain: :water_flow,
  target_domain: :electrical_circuit,
  mappings: [
    { source: :pressure, target: :voltage },
    { source: :flow_rate, target: :current },
    { source: :pipe_resistance, target: :resistance }
  ],
  mapping_type: :relational,
  strength: 0.8
)
```

## Usage

```ruby
client = Legion::Extensions::AnalogicalReasoning::Client.new

# Apply an analogy to map a source concept to the target domain
client.apply_analogy(analogy_id: id, source_element: :pressure)
# => { success: true, mapped: true, target_element: :voltage }

# Transfer knowledge across domains
client.cross_domain_transfer(
  analogy_id: id,
  source_knowledge: { high_pressure: :causes_fast_flow }
)

# Reinforce based on application success
client.reinforce_analogy(analogy_id: id, success: true)

# Find productive analogies
client.productive_analogies
# => { analogies: [...], count: 3 }

# Maintenance
client.update_analogical_reasoning
```

## Integration

Wire into reasoning phases where the agent needs to reason about unfamiliar domains by mapping from known domains. Transfer results can be stored as new semantic traces in lex-memory.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
