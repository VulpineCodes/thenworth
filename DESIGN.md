# Thenworth Design System

Green theme: deep forest green primary, warm ivory backgrounds, one
bright growth-green accent. Deliberately NOT a neon fintech green.
Premium, calm, and memorable, like a thoughtfully crafted Apple
product — not a generic budgeting dashboard, not a spreadsheet with an
app skin, not a gamified finance app, and definitely not a chatbot
with a calculator attached.

The tokens below are the source of truth as implemented in
`App/Models/DesignSystem.swift`. Every color has an explicit light and
dark variant.

## Palette

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `forestPrimary` | `#1E4D38` | `#8FC7A8` | Primary brand: buttons, selected states, the "let it grow" path |
| `forestDeep` | `#14382A` | `#B7DCC6` | Headers and emphasis on light backgrounds |
| `growthAccent` | `#2E8B57` | `#4CC07A` | One bright accent, used sparingly: the growth line, the gap shading, positive deltas |
| `ivoryBackground` | `#FAF6EC` | `#111A14` | App background (warm ivory / deep green-black) |
| `cardSurface` | `#FFFDF6` | `#1D2B22` | Card surface (warm white / lifted green-black) |
| `softBorder` | `#E3DCCB` | `#33473A` | Borders and dividers |
| `warmMuted` | `#5C665E` | `#A8B5AB` | Warm-toned secondary copy |

System secondary text is used where possible; `warmMuted` is for
warm-toned secondary copy. The accent is used sparingly on purpose:
one bright green, in the growth line and the gap, so it keeps meaning
"growth" instead of becoming decoration.

## Typography

System fonts throughout, so Dynamic Type and VoiceOver keep working.
Rounded design for display and titles, default for body.

| Token | Style |
| --- | --- |
| `thenworthDisplay` | Large title, rounded, bold — the headline future value |
| `thenworthTitle` | Title 2, rounded, semibold — screen titles |
| `thenworthHeadline` | Headline, semibold — section and card headings |
| `thenworthBody` | Body — body copy |
| `thenworthCaption` | Subheadline — secondary copy, footnotes, "hypothetical" notes |
| `thenworthFootnote` | Footnote — small labels and chips |

No custom fonts are bundled. No fixed tiny sizes.

## Spacing and radii

Spacing: xs 4, small 8, medium 16, large 24, xl 32. Radii: small 10,
card 16, large 24. Layouts are spacious, surfaces are rounded, and
controls are thumb-friendly (the timeline scrubber is a large slider
with year steppers, not a thin strip).

## Money formatting

One formatter (`MoneyFormat`) so every screen agrees. Amounts under
$100 show cents, because a $2.88 subscription matters; larger amounts
round to whole dollars. Rates render as percentages ("7%"). Time
renders as "20 years" / "1 year" and "18 months" / "1 month".

## The Future Lens

The signature interaction. Two paths diverge from the decision point
and the gap between them is shaded; the gap IS the tradeoff.

- The fork is drawn with Swift Charts: two `LineMark`s, an `AreaMark`
  shading the gap, a `RuleMark` at the scrubbed year.
- The growth path uses the growth accent; the other path uses forest
  tones. The shaded gap is the accent at low opacity.
- The timeline scrubber is large, with year steppers on either side.
  Scrubbing updates the chart, the figures, and the milestone line
  together (one Combine-derived lens, so they can never disagree).
- Figures count up as you scrub (`.contentTransition(.numericText())`),
  gated by reduced motion.
- A toggle switches between today's dollars (the default) and future
  dollars. The default matters: today's dollars are the honest,
  comparable number.
- A milestone line translates the gap into something concrete
  ("that's about a used car"), from the deterministic
  `Milestones.translation(for:)` in the core.
- Path labels are neutral: "Spend now" / "Let it grow", "Keep paying" /
  "Redirect it", "Your plan" / "Target", "Start at 30" / "Start at 23".
  Each scenario carries one short acknowledgment of what the first path
  gives you ("Spending gets you the thing today. That is real value
  too.").

## Home

The question first: "What does today mean for tomorrow?" Then four
scenario cards (One purchase, Monthly expenses, Save for something, My
retirement), each with a live mini-preview computed from the core
(e.g. the $100 card shows "$100 today, $X in 20 years"), plus a
start-from-scratch entry. The value of the app is visible immediately,
with no account, no financial data, and no internet connection.

## Accessibility

- Dynamic Type: system fonts, no fixed tiny sizes; the largest size
  must not clip text in cards or the lens figures.
- VoiceOver: the chart has a spoken summary, the slider announces the
  year, and controls carry accessibility labels and identifiers (the
  identifiers also serve the XCUITest tests).
- Reduced motion: the counting animation is gated off when
  accessibilityReduceMotion is on; scrubbing still updates the figures.
- Light and dark mode: every token has both variants; dark mode stays
  readable and the chart stays legible.

## Copy rules

- Calm, clear, and non-judgmental. Never shame spending. Every
  scenario says what spending gives you today.
- Hypothetical investment growth is always labeled hypothetical, never
  guaranteed. Money contributed, employer match, and growth are always
  distinguished. Nominal (future dollars) and real (today's dollars)
  are always distinguished.
- Short and plain. Education emerges from the experience (Learn Why),
  it does not interrupt it.

## What it is not

- No excessive glass effects, no generic dashboard cards, no
  unnecessary decoration, no overwhelming amounts of text.
- No gamification, no streaks, no badges.
- No chatbot. AI is not the interaction model.
- No neon green, no generic fintech look.
