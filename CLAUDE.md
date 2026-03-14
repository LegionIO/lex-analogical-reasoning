# lex-analogical-reasoning

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Analogical reasoning engine (Gentner structure mapping, Hofstadter, Holyoak multi-constraint) for brain-modeled agentic AI. Models the cognitive ability to find structural correspondences between domains, apply cross-domain mappings, and use productive analogies for knowledge transfer.

## Gem Info

- **Gem name**: `lex-analogical-reasoning`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::AnalogicalReasoning`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/analogical_reasoning/
  analogical_reasoning.rb      # Main extension module
  version.rb                   # VERSION = '0.1.0'
  client.rb                    # Client wrapper
  helpers/
    constants.rb               # Limits, thresholds, mapping types, state transitions
    analogy_engine.rb          # AnalogyEngine — manages analogies, similarity evaluation
    structure_map.rb           # StructureMap — individual analogy with mappings
  runners/
    analogical_reasoning.rb    # Runner module with 8 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
MAX_ANALOGIES        = 200
MAX_DOMAINS          = 50
MAX_HISTORY          = 300
SIMILARITY_THRESHOLD = 0.4   # minimum similarity to consider analogies related
STRUCTURAL_WEIGHT    = 0.7   # structural mappings outweigh surface features
SURFACE_WEIGHT       = 0.3
DEFAULT_STRENGTH     = 0.5
STRENGTH_FLOOR       = 0.05
STRENGTH_CEILING     = 0.95
REINFORCEMENT_RATE   = 0.1
DECAY_RATE           = 0.01
MAPPING_TYPES        = %i[attribute relational system]
ANALOGY_STATES       = %i[candidate validated productive stale]
STATE_THRESHOLDS     = { productive: 0.75, validated: 0.5, candidate: 0.25 }
```

## Runners

### `Runners::AnalogicalReasoning`

All methods delegate to a private `@engine` (`Helpers::AnalogyEngine` instance).

- `create_analogy(source_domain:, target_domain:, mappings:, mapping_type: :relational, strength: nil)` — create a structural mapping between two domains
- `find_analogies(domain:)` — find all analogies involving a domain
- `apply_analogy(analogy_id:, source_element:)` — map a source element to its target domain equivalent
- `evaluate_similarity(source:, target:)` — compute similarity score between two domains/elements
- `cross_domain_transfer(analogy_id:, source_knowledge:)` — transfer knowledge from source to target domain via analogy
- `reinforce_analogy(analogy_id:, success:)` — strengthen or weaken an analogy based on application outcome
- `productive_analogies` — return all analogies in `:productive` state
- `update_analogical_reasoning` — decay all analogies and prune stale ones
- `analogical_reasoning_stats` — stats hash

## Helpers

### `Helpers::AnalogyEngine`
Core engine. Manages the collection of StructureMap instances. `evaluate_similarity` uses weighted combination of structural (0.7) and surface (0.3) features. `cross_domain_transfer` applies the analogy's mapping table to transfer structured knowledge. `reinforce_analogy` adjusts strength and transitions state based on `STATE_THRESHOLDS`.

### `Helpers::StructureMap`
Individual analogy object. Stores `source_domain`, `target_domain`, `mappings` (array of correspondence pairs), `mapping_type`, and `strength`. State transitions: candidate → validated → productive (or → stale on decay).

## Integration Points

No actor defined — callers drive the lifecycle. Integrates with lex-memory for analogical retrieval: when the agent encounters a new situation, retrieve similar past situations via analogy. Wire into reasoning phases where the agent needs to reason about unfamiliar domains by mapping from familiar ones. Cross-domain transfer results can be fed as new semantic traces to lex-memory.

## Development Notes

- `STRUCTURAL_WEIGHT = 0.7` reflects Gentner's structure-mapping theory emphasis: relational structure matters more than surface features
- `mapping_type: :system` indicates higher-order relational mappings (systems of relations, not just individual correspondences)
- Analogy state is threshold-based on strength, not explicit transition methods
- `prune_stale` removes analogies in `:stale` state (decayed below `STRENGTH_FLOOR`)
