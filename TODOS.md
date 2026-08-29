# Whole Knowledge TODOs

Deferred product work accepted during the M1 Discovery CEO review. These items
are intentionally outside M1 unless a future task explicitly promotes them.

## P2 — Library search and organization

- **What:** Add server-backed search across content, meaning, context, source,
  and part of speech, plus All/Vocabulary/Expressions and newest/oldest
  controls.
- **Why:** Founder use has exposed real retrieval friction as the Library grows,
  but this does not prove the M1 Discovery interaction.
- **Pros:** Makes learned language findable; can reuse M1 normalized matching
  and bounded pagination patterns.
- **Cons:** Adds query, paging, empty, and filter states to a separate product
  surface.
- **Context:** Start with search, type, and chronological order. Add POS or
  due-state filters only if founder use demonstrates demand.
- **Effort:** M (human: ~3–4 days / Codex: ~4–6 hours).
- **Priority:** P2.
- **Depends on / blocked by:** M1 repository query work is useful leverage but
  not a hard blocker.

## P2 — Today's Captures surface

- **What:** Add a visible `Today's captures · N` affordance inside Capture that
  opens a vertically transitioned daily-discovery surface.
- **Why:** It may reinforce daily learning continuity if the M1 completion state
  and Today's existing recent-capture section prove insufficient.
- **Pros:** Makes the day's discoveries tangible; provides a direct path back to
  item detail.
- **Cons:** Duplicates existing continuity surfaces and adds another query,
  transition, loading state, and accessibility surface.
- **Context:** Tapping is the primary access method. Do not add vertical swipe
  unless founder use proves it helpful rather than conflicting with scrolling.
  Show only factual states such as first production completed or deferred.
- **Effort:** M (human: ~2–3 days / Codex: ~4–6 hours).
- **Priority:** P2, conditional on observed post-M1 friction.
- **Depends on / blocked by:** M1 Discovery completion and a bounded local-day
  capture query.

## P3 — Meaning Match recognition experiment

- **What:** Add one practice mode that matches vocabulary items to their
  selected meanings.
- **Why:** It can reuse Discovery data as a recognition surface without becoming
  a game economy.
- **Pros:** Adds lightweight varied practice; tests whether selected meanings
  support useful recognition.
- **Cons:** Requires distractor construction, eligibility rules, evidence
  storage, and a new success loop; recognition can be mistaken for production.
- **Context:** Make it available after at least eight eligible unique vocabulary
  items. Eligibility requires an active item, usable meaning, no duplicate
  surface/sense in the round, and sufficiently distinct pairings. Record Match
  as recognition evidence only and do not change Review scheduling initially.
- **Effort:** M (human: ~4–5 days / Codex: ~1 day).
- **Priority:** P3 experiment.
- **Depends on / blocked by:** M1 selected-sense quality and enough eligible
  founder data.

## P3 — Knowledge-pool visual exploration

- **What:** Explore whether truthful learning evidence benefits from a subtle
  spatial or strengthening metaphor.
- **Why:** A visual field might make accumulated knowledge easier to understand,
  but the proposed partial-circle states currently imply unsupported mastery
  precision.
- **Pros:** Preserves a potentially distinctive long-term identity and a way to
  make evidence legible at a glance.
- **Cons:** Risks decorative complexity, accessibility problems, fake precision,
  and premature graph architecture.
- **Context:** Do not presume nodes, circles, levels, or a graph backend. Start
  only after a validated evidence model and a demonstrated comprehension problem;
  compare any visualization against plain factual history.
- **Effort:** L (human: ~1–2 weeks / Codex: ~2–3 days for a credible prototype).
- **Priority:** P3 exploration.
- **Depends on / blocked by:** A validated evidence model and observed need for
  spatial progress feedback.

## P3 — Multilingual identity and provider routing

- **What:** Add explicit language identity, a persistent target-language
  default, language-aware re-encounter matching, and provider routing with
  complete manual fallback.
- **Why:** Same-spelling items can belong to different languages, while provider
  structures and licensing differ by language.
- **Pros:** Establishes truthful multilingual identity and a coherent path to
  additional lexical providers.
- **Cons:** Requires migration policy, settings, provider evaluation, and more
  Capture states before a second language has demonstrated demand.
- **Context:** Use BCP-47 tags, define migration treatment for existing items,
  keep Capture lightweight through a remembered default, and never infer a
  language from short input without manual correction.
- **Effort:** L (human: ~1–2 weeks / Codex: ~2–3 days).
- **Priority:** P3.
- **Depends on / blocked by:** Actual founder demand for a second target language
  and provider/licensing research.

## P3 — Deeper knowledge exploration and future Pro boundary

- **What:** Validate sourced exploration beyond the core loop: richer examples,
  dialogues, collocations, register, comparisons, readings, and related
  concepts.
- **Why:** A word can become a doorway into broader knowledge, but usefulness,
  sourcing, licensing, and cost must be proven before ingestion or monetization.
- **Pros:** Extends the Language OS thesis and creates a plausible value boundary
  for deeper paid exploration.
- **Cons:** Introduces content policy, licensing, provider, navigation, and
  operational complexity; essential usage information is easy to paywall by
  mistake.
- **Context:** Keep Capture, selected senses, essential examples, first
  production, Review, Library, and basic recognition practice free. Collocations
  and register remain free when needed for correct use. Preferred positioning:
  "Free helps you learn and use it. Pro helps you follow it further."
- **Effort:** L for product/content validation; implementation deliberately
  unestimated.
- **Priority:** P3.
- **Depends on / blocked by:** Repeated founder use of M1, evidence of demand for
  deeper material, and source/licensing research.
