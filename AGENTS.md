# Whole Knowledge Agent Guide

## Product identity

Whole Knowledge is a personal Language OS, not merely a vocabulary or flashcard application. It should support a durable learning loop:

```text
Capture
→ Understand
→ Retrieve
→ Produce
→ Analyze mistakes
→ Reuse
```

The main product is a standalone Flutter application. It is not an Obsidian plugin.

## Engineering rules

- Use Flutter and Dart for the main application.
- Prefer simple architecture over speculative abstractions.
- Keep business logic independent from widgets.
- Core functionality must not require a cloud service; local-first is the intended direction.
- Add dependencies only for a concrete, current need.
- Do not silently change state management, navigation, persistence, or backend architecture.
- Keep files focused and reasonably small.
- Use current Flutter and Dart APIs.
- Consult Context7 and current package documentation when an API is uncertain.
- Use the official Flutter/Dart Codex plugin and skills where applicable.
- Maintain Linux desktop and Android compatibility.
- Accessibility is required, including keyboard navigation, focus visibility, readable contrast, semantics, and responsive text/layout behavior.
- Run formatting, analysis, tests, and the relevant target build before declaring work complete.

## Design rules

- Use `shadcn_ui` as the component foundation.
- Aim for shadcn/ui restraint with a distinct Whole Knowledge identity, not a literal web clone.
- Keep the interface minimal, calm, content-first, neutral, highly legible, spacious, and low in cognitive load.
- Design for desktop quality while remaining mobile-compatible.
- Prefer subtle 1px borders, restrained radii, strong typography hierarchy, neutral surfaces, clear focus states, generous whitespace, and compact controls.
- Centralize semantic colors, spacing, radii, and component theme values. Do not scatter raw design values through widgets.
- Keep light and dark themes structurally supported. Dark mode may be the primary development reference.
- Preserve one replaceable semantic brand-accent token, but do not lock the final brand color without an explicit design decision.
- No Duolingo-inspired UI.
- No cartoon mascots, childish gamification, bright lime language-learning colors, fake streaks, or decorative rewards.
- Avoid giant rounded cards, excessive pills or shadows, decorative gradients, neon colors, glassmorphism, oversized SaaS KPI dashboards, arbitrary animation, and decoration without function.

## Testing

- Format with `dart format .`.
- Analyze with `flutter analyze`.
- Run tests with `flutter test`.
- Verify the primary desktop target with `flutter build linux`.
- Add focused widget tests for user-visible shell or component behavior.
- Add regression tests when fixing a bug.

## Skill routing

- Product discovery and scope: `gstack-office-hours` or `gstack-plan-ceo-review`.
- Architecture review: `gstack-plan-eng-review`.
- Design-system planning: `gstack-design-consultation` or `gstack-plan-design-review`.
- Bugs and root-cause analysis: `gstack-investigate`.
- Code review: `gstack-review`.
- QA: `gstack-qa` or `gstack-qa-only`.
- Shipping: `gstack-ship`.
- Destructive or production-sensitive work: `gstack-careful` or `gstack-guard`.
