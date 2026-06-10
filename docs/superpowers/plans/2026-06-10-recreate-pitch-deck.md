# Recreate Pitch Deck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recreate the Emerge Pitch Deck programmatically in Python following the Cover, Problem, Solution, Market, Product, Business Model, Traction, Competition, Go to Market, Teams, Financial, and Ask flow with updated local metrics and strategic plans.

**Architecture:** We will modify `docs/create_pitch_deck.py` directly. The script uses the `pptx` library to create a 13.333" x 7.5" (16:9) presentation. We will implement helper functions for custom card drawing, table building, and text positioning to ensure a premium dark-violet visual aesthetic.

**Tech Stack:** Python 3, `python-pptx`

---

## Technical Helpers Reference

To draw tables and complex cards programmatically in `python-pptx`, the following functions will be implemented or updated in the script:

```python
def add_table(slide, rows, cols, left, top, width, height):
    """Adds a table shape with custom coordinates."""
    table_shape = slide.shapes.add_table(rows, cols, left, top, width, height)
    return table_shape.table

def add_bullet_text(slide, left, top, width, height, items, font_size=16, color=WHITE, bullet_color=ACCENT_GOLD):
    """Adds a box with multiple bullet items."""
    txBox = slide.shapes.add_textbox(left, top, width, height)
    tf = txBox.text_frame
    tf.word_wrap = True
    for i, item in enumerate(items):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.text = item
        p.font.size = Pt(font_size)
        p.font.color.rgb = color
        p.font.name = 'Calibri'
        p.space_after = Pt(8)
        p.level = 0
    return txBox
```

---

## Tasks

### Task 1: Setup, Color Palette, and Layout Helpers

**Files:**
- Modify: `docs/create_pitch_deck.py` (Lines 15-110)

- [ ] **Step 1: Set up the correct color palette and window dimensions**
  Ensure the colors reflect the premium dark violet theme and accents:
  ```python
  DEEP_VIOLET = RGBColor(0x2A, 0x1B, 0x4E)
  DARK_PURPLE = RGBColor(0x1A, 0x0E, 0x33)
  MID_PURPLE = RGBColor(0x4A, 0x30, 0x80)
  ACCENT_GOLD = RGBColor(0xFF, 0xD7, 0x00)
  ACCENT_CYAN = RGBColor(0x00, 0xE5, 0xFF)
  ACCENT_GREEN = RGBColor(0x00, 0xE6, 0x76)
  ACCENT_CORAL = RGBColor(0xFF, 0x6B, 0x6B)
  WHITE = RGBColor(0xFF, 0xFF, 0xFF)
  LIGHT_GRAY = RGBColor(0xCC, 0xCC, 0xCC)
  SOFT_WHITE = RGBColor(0xF0, 0xF0, 0xF0)
  SLIDE_BG = RGBColor(0x0F, 0x0A, 0x1E)
  CARD_BG = RGBColor(0x1E, 0x14, 0x3B)
  ```
- [ ] **Step 2: Add or refine helper methods**
  Add helper methods `add_shape`, `add_text_box`, `add_metric_card`, and `add_accent_line` if they are not fully matching the custom card specifications.
- [ ] **Step 3: Test environment dependencies**
  Run: `python -c "import pptx"` to verify `python-pptx` is installed.
  Expected: Command executes with 0 exit code (no import error).

### Task 2: Implement Cover, Problem, and Solution Slides

**Files:**
- Modify: `docs/create_pitch_deck.py`

- [ ] **Step 1: Recreate Slide 1 (Cover)**
  Build a centered cover slide with:
  ```python
  # Cover Content
  add_text_box(slide, Inches(1.5), Inches(1.5), Inches(10), Inches(1.2), "EMERGE", font_size=72, color=WHITE, bold=True, alignment=PP_ALIGN.CENTER)
  add_accent_line(slide, Inches(5), Inches(2.8), Inches(3.3), ACCENT_GOLD)
  add_text_box(slide, Inches(2), Inches(3.2), Inches(9), Inches(0.8), "The Identity-First Habit Ecosystem", font_size=32, color=ACCENT_GOLD, alignment=PP_ALIGN.CENTER)
  add_text_box(slide, Inches(2), Inches(4.2), Inches(9), Inches(0.8), "Transforming who you are, one vote at a time.", font_size=20, color=LIGHT_GRAY, alignment=PP_ALIGN.CENTER)
  ```
- [ ] **Step 2: Recreate Slide 2 (Problem)**
  Build a 3-card layout highlighting the outcome-focused habit app failures:
  * Stat 1: 92% Failure Rate (abandon goals by February).
  * Stat 2: 95% Churn Rate (quit trackers within 30 days).
  * Stat 3: The Outcome Trap (Focus on outcomes "I want to lose weight" instead of identity "I am an athlete").
- [ ] **Step 3: Recreate Slide 3 (Solution)**
  Build a 3-card layout detailing Emerge:
  * 🎭 Identity-First (choose who to become).
  * 🗳️ Vote System (habit as identity evidence).
  * 🤖 AI Life Coach (dynamic difficulty adjustments).
- [ ] **Step 4: Verify Script Output**
  Run: `python docs/create_pitch_deck.py`
  Expected: Execution prints slide count and saves the file.

### Task 3: Implement Market, Product, and Business Model Slides

**Files:**
- Modify: `docs/create_pitch_deck.py`

- [ ] **Step 1: Recreate Slide 4 (Market)**
  Build 3 metric cards at the top:
  * Card 1: ₦17.6 Trillion (Global market size).
  * Card 2: ₦209 Billion (Nigeria Online Fitness size growing at 29.14% CAGR).
  * Card 3: ₦383 Billion (Nigeria Mental Wellness projection by 2033).
  Build a 2-column detailed breakdown comparing the digital-native audience of Nigeria (120M+ smartphone users) with global feature gaps.
- [ ] **Step 2: Recreate Slide 5 (Product)**
  Describe the RPG onboarding, character creator studio, and the Habit Stack builder. Outline the Flame game engine integration (City & Forest dynamic visuals).
- [ ] **Step 3: Recreate Slide 6 (Business Model)**
  Details:
  * Freemium Subscriptions: ₦2,500/month, ₦20,000/year.
  * Advertising: Banner/interstitial ads for free tier.
  * Affiliate Rewards: Companies sponsor challenges and reward user habits.
  Visual: A table grid showing Free Tier restrictions vs. Emerge Pro capabilities.
- [ ] **Step 4: Verify Slides Build**
  Run: `python docs/create_pitch_deck.py`
  Expected: Slide count is updated.

### Task 4: Implement Traction, Competition, and Go-to-Market Slides

**Files:**
- Modify: `docs/create_pitch_deck.py`

- [ ] **Step 1: Recreate Slide 7 (Traction)**
  Details:
  * Metrics: 50+ beta testing users, 1,000+ completed stacks.
  * Platforms: Deployed on Android and Web (iOS planned). Do NOT include Windows.
- [ ] **Step 2: Recreate Slide 8 (Competition)**
  Build a direct grid matrix table mapping:
  * Competitors: Habitica, Fabulous, Streaks, Emerge.
  * Columns: Identity-First, Visual Worlds, AI Coach, Naira Pricing & Rewards, Low-Data Sync.
- [ ] **Step 3: Recreate Slide 9 (Go-To-Market)**
  Detail the acquisition growth loop:
  * Phase 1: Creator Blueprints (influencer-designed routines).
  * Phase 2: Tribal Challenges (reward-sharing social loops).
  * Phase 3: B2B corporate wellness pilots.
- [ ] **Step 4: Verify Slide Progression**
  Run: `python docs/create_pitch_deck.py`

### Task 5: Implement Team, Financial, and Ask Slides

**Files:**
- Modify: `docs/create_pitch_deck.py`

- [ ] **Step 1: Recreate Slide 10 (Team)**
  Details:
  * Sole Founder (Full-Stack Engineer).
  * Key Hires Needed: Marketing Expert (user acquisition/B2B), Rive Animator (premium interface UI animations), Business Consultant (corporate deals).
- [ ] **Step 2: Recreate Slide 11 (Financials)**
  Add a clean PPTX table displaying Year 1 to Year 3 conservative user growth and revenue streams:
  * Year 1: 50,000 Users | 3% Conv | ₦45M Subs | ₦15M Ads/Affiliates | **₦60M Total**
  * Year 2: 250,000 Users | 5% Conv | ₦330M Subs | ₦95M Ads/Affiliates | **₦425M Total**
  * Year 3: 1,000,000 Users | 7% Conv | ₦1.68B Subs | ₦372M Ads/Affiliates | **₦2.05B Total**
- [ ] **Step 3: Recreate Slide 12 (Ask)**
  Details:
  * Funding Request: ₦10,000,000
  * Split: 50% Marketing (₦5.0M), 30% Further Development (₦3.0M), 20% B2B Expansion (₦2.0M)
  * Visual: Progress/horizontal bars showing funding allocation.
- [ ] **Step 4: Final Generation & Verify Slide Count**
  Run: `python docs/create_pitch_deck.py`
  Expected: Success output confirming 12 slides generated and saved as `docs/Emerge_Pitch_Deck.pptx`.
