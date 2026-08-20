# The Four Foundations: Product, Persona, Competition, Market

The four pillars of the guidebook's Market Research section, industrialized.
Read the pillar you're working on. Sources cited inline; figures found in
sources are marked with a date; everything else is a labeled heuristic.

---

## Pillar 1 — Product Details & Value Articulation

The job: turn a product's mechanics into **claims people repeat**. For Emerge
the raw material is rich: an identity-first mechanic (avatar/world grows with
habits), forgiving design ("Never miss twice"), sponsor-quest rewards.

### Repeatable process

1. **Inventory features from source, not memory.** Walk the product — for
   Emerge: `lib/features/*` and the onboarding copy — list every shipped
   feature as a noun phrase.
2. **Map `feature → benefit → emotion`.** One line per feature. Benefit = "so
   you can…"; emotion = the feeling it produces.
   - *feature:* avatar physically grows → *benefit:* watch discipline
     accumulate → *emotion:* pride, proof of becoming.
3. **Pain → solution reframe.** For each feature, state the pain it kills.
   Habits Garden leads with the pain: "80% of New Year's resolutions fail in 2
   months" (habitsgarden.com) — pain hook first, not mechanics.
4. **Write 1–3 JTBD statements.**
   `When [situation], I want to [action], so I can [progress toward a better
   self].` JTBD is anti-demographics; it captures the progress a customer hires
   the product for (en.wikipedia.org/wiki/Jobs_to_be_done).
5. **Write the positioning statement** (template in SKILL.md) — one sentence you
   can fight over, then 2 alternatives and diff.

   > For identity-seeking starters in Nigeria who quit after the first slip,
   > Emerge is the habit app that makes discipline visible, unlike streak-based
   > trackers that punish one missed day.

6. **Collect proof assets in a living doc:** testimonials (verbatim + consent),
   ratings, download counts, sponsor logos, founder story, press. Pattern the
   leaders use: **number + credential together** — Forest "60M+ downloads,
   Editors' Choice, 4.8 rating" (forestapp.cc); Habits Garden "4.8/5 from
   17,742 achievers" (habitsgarden.com).

### Prompts

- "Read `lib/features/*` and onboarding copy. Output: feature | user-facing
  benefit | emotion."
- "Extract each competitor's positioning statement word-for-word from its
  landing page; list the pains each claims to solve."
- "Turn these 40 features into 5 benefit-first value props, one sentence each,
  no jargon."
- "Write 3 JTBD statements for: a Lagos-based young professional, a university
  student, a neurodivergent user needing structure."
- "From these testimonials, write 3 app-store descriptions (140/400/1000
  chars), strongest verbatim quote first."

### Common mistakes & validation

- **Feature dumps** (ending in mechanics) — every line must end in a benefit.
- **Benefit/feature confusion** — "grows your avatar" is a feature; "proves
  you're becoming a disciplined person" is the benefit.
- **Skipping emotion** — habit apps sell the aspiration, not the utility.
- **Fabricated proof** — never invent testimonials or numbers.
- *Validate:* every claim traces to a shipped feature or a real verbatim;
  an outsider reads the positioning aloud in <30s without explanation.

---

## Pillar 2 — Target-Audience Persona

### Process (when there is NO first-party data)

1. **Start with behavior, not demographics.** Personas "should be based on
   information about real people," not invention (NN/g,
   nngroup.com/articles/persona/).
2. **Run 5–10 rapid interviews** with existing users (waitlist, beta, first
   installs, sponsor prospects). A small real sample beats a big invented one.
3. **Mine lookalike communities for real language** (your primary no-data
   source):
   r/getdisciplined, r/selfimprovement, r/productivity, r/Habits,
   r/DecidingToBeBetter, r/ADHD, r/adhdwomen, r/Nigeria; X Nigerian self-help
   circles; Facebook groups; WhatsApp communities. Save verbatim complaints and
   aspirations — these become persona quotes.
4. **Segment by behavior** once analytics exist (install source, feature usage,
   streak behavior, sponsor-quest completers vs free-cyclers).
5. **Cluster into 2–3 personas** (eliminate the least business-relevant), then
   fill the template. Pick **ONE niche first**.

### The persona template (fill every field or delete it)

- **Demographics** — age, gender, education, income, city.
- **Geographic location** — country/region, language, timezone (Nigerian GMT+1
  matters for scheduling + sponsor campaigns).
- **Psychographics** — identity/life-stage, values (discipline, growth, proof),
  motivation type.
- **Professional background** — role, work mode, screen time, stress sources.
- **Pain points & challenges** — why past habit apps failed, verbatim quotes.
- **Goals & aspirations** — the "future self" 5 years out.
- **Shopping habits & preferences** — free-first culture, willingness to pay
  (Paystack), subscription vs lifetime, referral behavior.
- **Media consumption** — TikTok/IG Reels/YT Shorts, X/LinkedIn,
  WhatsApp/Facebook Groups, which creators.
- **Influencers & decision-makers** — who they follow/trust, who approves spend.
- **Brand perceptions & preferences** — what they believe about habit apps
  ("streaks are stressful"), what premium means to them.

*Note:* this mirrors the guidebook's persona prompt fields (demographics,
geography, psychographics, professional background, pain points/goals,
shopping habits, media consumption, influencers/decision-makers, brand
perceptions) — see `prompts.md`.

### Emerge suggested niche order (identity-seekers)

1. **Lagos/Abuja early-career professional (25–34)** — income upside, sponsor
   appeal, strong "becoming" narrative, active on TikTok + X.
2. **University student** — volume + virality, cheapest acquisition; weaker
   paying power but the sponsor-quest model monetizes them anyway.
3. **Neurodivergent user needing structure** — underserved on r/ADHD (high
   engagement); "Never miss twice" is literally built for them.
4. **Fitness/wellness seeker** — crowded; a *follow-on* niche, not the first.

Niche cut-off test: peak felt-pain × reachable community × monetization
(sponsors love a vivid, reachable demo) × content surface (can you produce 5
video angles?).

### Prompts

- "From these 8 transcripts + 40 Reddit quotes, cluster pain points into 3
  behavioral segments, each with a hire metaphor ('I hired Emerge because…')."
- "Draft persona cards using the template; every quote verbatim from raw data,
  not paraphrased. Mark assumed fields with [ASSUMPTION]."
- "Rank candidate first-niches on felt pain, community reachability, sponsor
  appeal, content surface. Recommend one with a scored matrix."

### Common mistakes & validation

- **Invention-as-research** — polished fake personas don't persuade.
- **Too many segments** — 6 personas = no persona; 1–3, focus on one.
- **Demographics-only** — age/city without pain/goals tells you nothing.
- **Confirmation bias** — include disconfirming voices.
- **Permanent personas** — refresh with analytics once real usage exists.
- *Validate:* every field traces to a quote/community/interview or is labeled
  `[ASSUMPTION]`; a real user reading it says "yes, that's me" (test with 3–5).

---

## Pillar 3 — Competitor Analysis

### The framework

1. **Cast the net** — app-store search for the category terms, Reddit/YouTube
   recommendations. Emerge's named set: Habitica, Habits Garden, everyday.app,
   Polar Habits, Forest, Done.
2. **Winnow to top 3–5** by relevance to your niche (identity/visual progress),
   traction, recency.
3. **Capture each in a card** — positioning statement (verbatim), core claims,
   features, pricing, platforms, distribution, marketing voice.
4. **Mine reviews (the core evidence act)** — pull 20+ recent reviews per
   competitor (Google Play + App Store); split positive/negative; **themed-count**
   ("motivation", "streak pressure", "price", "sync bugs", "rewards"); convert
   themes to pros/cons. Visible signals today: Forest = "no shame, no
   preaching" + real-world impact (2M real trees, forestapp.cc); Habits Garden
   = "$5/mo with lifetime option" + "If you enjoyed Atomic Habits, you'll love
   this" (habitsgarden.com); Habitica = "Gamify Your Life" RPG framing
   (habitica.com).
5. **Feature matrix** — drivers (rows) × competitors (columns), ✓/✗/partial;
   highlight where you're alone.
6. **Differentiation map** — 2 axes (e.g., utilitarian vs identity/emotional;
   punishing vs forgiving). Emerge's "Never miss twice" is a genuinely
   distinct lane.
7. **Weakness → opportunity** — for each top negative theme, write your
   counter-position (e.g., "streak apps make me feel guilty" → "Emerge forgives
   one miss"; "price blocks me" → "free + sponsor-funded rewards").

### Prompts

- "List the 10 most-cited habit apps in r/productivity and r/Habits this year;
  rank by mention; pick the 5 most relevant to an identity-first visual-progress
  app."
- "Export 25 recent reviews per app → 3 praised themes with quotes, 3
  complained themes with quotes, and theme counts."
- "Build the feature matrix; mark where Emerge is differentiated; write a
  SWOT row per competitor."
- "Synthesis: 'the biggest pain our top competitor's users review about is ___
  so we should ___'."

### Common mistakes & validation

- **Copying the leader's positioning** (becomes a worse Habitica).
- **Review cherry-picking** — use 20+ and count themes.
- **Snapshot analysis** — re-run the matrix quarterly.
- **Vanity metrics** — prefer review themes + feature completeness.
- *Validate:* claims trace to a dated, fetchable page or review;
  ≥20 reviews per competitor, theme frequencies counted;
  the diff map reflects reviewer language, not your preferences.

---

## Pillar 4 — Market Research

### Repeatable process

1. **State the question/hypothesis** (Ahrefs step 1,
   ahrefs.com/blog/market-research/): e.g., "Is there measurable demand for
   identity-based habit apps in Nigeria vs feature-based ones?"
2. **Size the market two ways.** **TAM** = total demand if 100% captured,
   **SAM** = slice reachable by your distribution/footprint, **SOM** = share
   realistically achievable (en.wikipedia.org/wiki/Total_addressable_market).
   Do **top-down** (industry figures × %) *and* **bottom-up**
   (units × price × realistic capture) and reconcile. Bottom-up grounds SOM;
   a top-down TAM alone is investor theater.
3. **Mine demand signals** — see `trend-research.md`.
4. **Keyword research** (Backlinko 7-step, backlinko.com/keyword-research):
   brainstorm from Reddit/forums/autosuggest → validate volume+difficulty →
   prioritize long-tails → check search intent → mine Search Console → target
   page-2 keywords competitors abandon.
5. **Primary research:** surveys (Google Forms/Typeform to waitlist/beta),
   5–10 interviews, intercept polls in Nigerian communities.
6. **Compile with evidence labels** (primary/secondary + source + date), then
   present: question → method → data → conclusion → recommended action.

### Prompts

- "Size TAM/SAM/SOM for a paid habit-tracker app in Nigeria bottom-up:
  smartphone users × % who install self-help apps × % who pay. Show every
  assumption and source. Then repeat top-down. Diff the two."
- "From Google Trends list topics related to 'habit tracker' + 'self
  improvement' with rising/breakout status in Nigeria, last 12 months; flag
  seasonality."
- "Give estimated monthly volume + competition for 'habit tracker app',
  'how to build discipline' and 5 long-tails; sort by intent."
- "Search r/getdisciplined, r/productivity, r/Nigeria for the top recurring
  habit-app complaints; quote 10 threads with timestamps."
- "Synthesis: a 3-sentence demand verdict for the Nigerian beachhead with the
  two strongest supporting numbers and one counter-signal."

### Free tools / sources

- Google Trends — trends.google.com/trends
- Google Keyword Planner — ads.google.com/home/tools/keyword-planner/
- AnswerThePublic — answerthepublic.com
- Exploding Topics — explodingtopics.com
- Reddit — r/productivity, r/getdisciplined, r/selfimprovement, r/Habits,
  r/Nigeria (filter by top/time)
- DataReportal Digital reports (Nigeria editions) — datareportal.com
- Statista — statista.com (Consumer Insights / Digital Market Outlook)
- Nigeria Bureau of Statistics — nigerianstat.gov.ng
- Think with Google — thinkwithgoogle.com
- Review aggregators named by Ahrefs: G2, Capterra, Trustpilot, Pew
- Surveys: Google Forms, Typeform (free tiers)
- App stores: your own App Store Connect / Play Console data

### Common mistakes & validation

- **Top-down fantasy** — anchoring SOM to bottom-up reality.
- **Opinion as evidence** — a hunch or one Reddit rant is a hypothesis.
- **Volume ≠ intent** — check search intent.
- **Ignoring local context** — Nigerian payment behavior (Paystack, transfer),
  data/airtime costs, Play billing quirks.
- **Spoofable sources** — require 2+ independent sources.
- *Validate:* every figure has a named source + date, primary/secondary is
  explicit, TAM/SAM/SOM arithmetic is written out and re-runnable, and any
  source that contradicts the thesis is included, not hidden.
