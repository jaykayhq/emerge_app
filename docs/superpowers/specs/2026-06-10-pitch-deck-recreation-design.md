# Design Spec: Emerge Pitch Deck Recreation

This document details the technical and design specifications for recreating the Emerge Pitch Deck. The deck will be generated programmatically as a PowerPoint presentation (`.pptx`) using Python, maintaining the premium brand identity of Emerge while implementing the user's specific 12-slide structure, traction data, monetization strategy, team composition, and funding ask.

## 1. Objectives & Guidelines

*   **Structure:** Recreate the presentation into a strict 12-slide flow: Cover, Problem, Solution, Market, Product, Business Model, Traction, Competition, Go to Market, Teams, Financial, and Ask.
*   **Visual Style:** Follow **Approach 1 (Modern Card-Based Identity Engine)**:
    *   Dark, high-contrast violet background (`#0F0A1E`) to match the gamified RPG theme.
    *   Fills using a slightly lighter card color (`#1E143B`) with colored border outlines.
    *   Neon accents to create premium visual focal points: Gold (`#FFD700`), Cyan (`#00E5FF`), Green (`#00E676`), and Coral (`#FF6B6B`).
    *   Clean typography spacing using standard PowerPoint system fonts (e.g. `Calibri` or `Arial`).
*   **Platform Correction:** Remove Windows support reference. Specify platforms as Android and Web (active), and iOS (planned).

---

## 2. Color Palette & Design Tokens

```python
# Colors defined in python-pptx RGBColor format
SLIDE_BG = RGBColor(0x0F, 0x0A, 0x1E)     # Deep dark violet
CARD_BG = RGBColor(0x1E, 0x14, 0x3B)      # Lighter violet for slide cards
MID_PURPLE = RGBColor(0x4A, 0x30, 0x80)   # Borders and sub-dividers
WHITE = RGBColor(0xFF, 0xFF, 0xFF)        # Primary text
LIGHT_GRAY = RGBColor(0xCC, 0xCC, 0xCC)   # Secondary text
SOFT_WHITE = RGBColor(0xF0, 0xF0, 0xF0)   # High-contrast body text

# Accent Highlights
ACCENT_GOLD = RGBColor(0xFF, 0xD7, 0x00)  # Brand highlight / Core metrics
ACCENT_CYAN = RGBColor(0x00, 0xE5, 0xFF)  # Info / Links / Subscriptions
ACCENT_GREEN = RGBColor(0x00, 0xE6, 0x76) # Success / Traction / Solved problems
ACCENT_CORAL = RGBColor(0xFF, 0x6B, 0x6B) # Pain points / Problem / Churn
```

---

## 3. Slide-by-Slide Contents & Layouts

### Slide 1: Cover
*   **Layout:** Centered typography with top-border gold line.
*   **Content:**
    *   Title: `EMERGE` (Font size: 72, Bold, White)
    *   Subtitle: `The Identity-First Habit Ecosystem` (Font size: 32, Accent Gold)
    *   Tagline: `Transforming who you are, one vote at a time.` (Font size: 20, Light Gray)
    *   Footer: `Investor Pitch Deck • 2026` | `Flutter • Firebase • AI Behavioral Science`

### Slide 2: The Problem
*   **Layout:** Title at the top left, three horizontal problem cards spanning the width of the slide.
*   **Content:**
    *   Title: `THE PROBLEM` (Accent Coral border line)
    *   Card 1: **92% Failure Rate** (of people abandon New Year's resolutions by February).
    *   Card 2: **95% Churn Rate** (of habit tracker users quit within the first 30 days due to boredom).
    *   Card 3: **Outcome Focus Trap** (Traditional apps track outcomes ["I want to lose weight"] rather than identity ["I am an athlete"], neglecting the core driver of behavior change).

### Slide 3: The Solution
*   **Layout:** Title at the top, followed by 3 vertical solution cards.
*   **Content:**
    *   Title: `THE SOLUTION` (Accent Green border line)
    *   Card 1 (🎭 Identity-First): Focuses on *who* the user wishes to become, not just what they track.
    *   Card 2 (🗳️ The Vote System): Every completed habit is a "vote" that creates proof of their identity.
    *   Card 3 (🤖 AI Life Coach): Gemini-powered personal guidance that scales challenges dynamically.

### Slide 4: The Market
*   **Layout:** Top row: 3 key market size metric cards. Bottom row: 2-column detailed breakdown of the Nigerian and global market.
*   **Content:**
    *   Metric Card 1: `₦17.6 Trillion` (Global Habit Tracker Market).
    *   Metric Card 2: `₦209 Billion` (Nigeria Online Fitness Market, CAGR 29.14%).
    *   Metric Card 3: `₦383 Billion` (Nigeria Mental Wellness Projection by 2033).
    *   Left Column: **Nigeria Opportunities** (120M+ smartphone users, growing interest in wellness, zero local gamified habit tools).
    *   Right Column: **The Gap** (No current global app offers hyper-localized Naira pricing or regional B2B challenges).

### Slide 5: The Product
*   **Layout:** Two columns: RPG Character Creator Studio (left) and Habit Stack Builder (right).
*   **Content:**
    *   Left Column (Future Self Studio): Visual onboarding selecting character classes (Athlete, Creator, Scholar, Stoic, Explorer, Zealot).
    *   Right Column (Habit Stack Builder): Drag-and-drop sequencing ("After [Anchor], I will [New Habit]").
    *   Highlight: Flame-engine dynamic maps (City & Forest) that grow or decay depending on user votes.

### Slide 6: The Business Model
*   **Layout:** Top row: 3 pricing cards. Bottom row: Large feature grid mapping Free vs. Emerge Pro.
*   **Content:**
    *   **Monetization Streams:**
        1.  *Subscriptions:* Freemium ₦2,500/monthly, ₦20,000/yearly.
        2.  *Ads:* Banner and interstitial ads for free tier.
        3.  *Affiliate Rewards:* Commercial partners sponsor challenges and pay to reward users.
    *   **Pro Entitlements:** Unlimited habits, full analytics heatmaps, premium visual world skins, advanced AI Coach logs, ad-free experience.

### Slide 7: Traction
*   **Layout:** Large metric card on the left. High-impact bulleted milestones on the right.
*   **Content:**
    *   Metric Card: `50+ Users` (Active Beta Cohort).
    *   Platform Badges: Deployed on **Android** and **Web**; **iOS** build prepared.
    *   Key Achievements: Over 1,000+ habit completions registered, 60% weekly active user (WAU) retention in early tests.

### Slide 8: The Competition
*   **Layout:** Feature comparison matrix table comparing Emerge, Habitica, Fabulous, and Streaks.
*   **Content:**
    *   Features compared: Identity-First Focus, Living Worlds, AI Coaching, Naira Pricing/Local Challenges, Offline-First Sync.
    *   Result: Emerge covers all four boxes, while competitors miss critical localization and identity-first psychology.

### Slide 9: Go-to-Market
*   **Layout:** 3 horizontal flow cards representing the viral acquisition model.
*   **Content:**
    *   Phase 1 (Creator Blueprints): Partnerships with local fitness trainers and career coaches to sell custom routines.
    *   Phase 2 (Tribal Invites): In-app group challenges that reward participants via affiliate brand coupons.
    *   Phase 3 (B2B Wellness): Launching corporate health pilots with customized company tribes.

### Slide 10: The Team
*   **Layout:** Prominent Solo Founder card on the left, flanked by 3 "Planned Key Hires" cards on the right.
*   **Content:**
    *   **Sole Founder:** Full Stack Flutter Architect & Identity UX Planner (builds backend/frontend).
    *   **Key Future Hires:**
        1.  *Marketing Expert:* Drives user acquisition, manages growth loops, and handles corporate partnerships.
        2.  *Rive Animator:* Builds premium, high-performance fluid character leveling and world progression animations.
        3.  *Business Consultant:* Leads B2B business development, enterprise licensing, and contract structures.

### Slide 11: Financials
*   **Layout:** Projection table detailing user metrics and revenue flows over 3 years.
*   **Content:**
    *   Year 1: 50,000 Users | 3% Conv. (1,500 Pro) | ₦45M Subs | ₦15M Ads/Affiliates | **₦60M Total**
    *   Year 2: 250,000 Users | 5% Conv. (12,500 Pro) | ₦330M Subs | ₦95M Ads/Affiliates | **₦425M Total**
    *   Year 3: 1,000,000 Users | 7% Conv. (70,000 Pro) | ₦1.68B Subs | ₦372M Ads/Affiliates | **₦2.05B Total**

### Slide 12: The Ask
*   **Layout:** Large headline highlighting the funding request, followed by 3 horizontal allocation cards.
*   **Content:**
    *   Funding Request: `₦10,000,000 Pre-Seed`
    *   **Allocation Split:**
        *   **50% Marketing (₦5.0M):** Local campaign launches, creator commissions, user acquisition.
        *   **30% Further Development (₦3.0M):** Hiring Rive animator support, launching iOS build, optimizing Flame renderer.
        *   **20% B2B Expansion (₦2.0M):** Custom dashboard for companies, enterprise marketing collateral.
    *   **Target Milestones:** Path to 250,000 users and ₦425M annual revenue.

---

## 4. Code Implementation Strategy

The script `docs/create_pitch_deck.py` will be modified in-place to implement the slide contents detailed above. We will:
1.  Verify the slide layouts in `python-pptx` (specifically using the blank layout `prs.slide_layouts[6]` to allow complete custom coordinate drawing).
2.  Enhance custom helper methods (`add_shape`, `add_text_box`, `add_metric_card`) to enforce modern styling, padding, and font metrics.
3.  Add specialized helper methods:
    *   `add_table` for Slide 8 (Competition matrix) and Slide 11 (Financials table).
    *   `add_allocation_bar` for Slide 12 (Ask split visualization).
4.  Remove references to Windows app availability, updating the tech stack and platforms to highlight Web, Android, and planned iOS.
5.  Generate the PPTX and verify script execution.
