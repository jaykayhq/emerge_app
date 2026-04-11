#!/usr/bin/env python3
"""
Emerge Pitch Deck Generator
Creates a comprehensive investor pitch deck for Emerge - The Identity-First Habit Ecosystem
Uses Naira (₦) for all financials. Follows the Habit Formation Blueprint structure.
"""

from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
import os

# ============================================================================
# DESIGN SYSTEM
# ============================================================================
# Emerge Brand Colors (Deep Violet palette from app_icon background #2A1B4E)
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
DARK_TEXT = RGBColor(0x1A, 0x1A, 0x2E)
SLIDE_BG = RGBColor(0x0F, 0x0A, 0x1E)
CARD_BG = RGBColor(0x1E, 0x14, 0x3B)

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)

SLIDE_W = prs.slide_width
SLIDE_H = prs.slide_height


def set_slide_bg(slide, color):
    background = slide.background
    fill = background.fill
    fill.solid()
    fill.fore_color.rgb = color


def add_shape(slide, left, top, width, height, fill_color, border_color=None, corner_radius=None):
    shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE if corner_radius else MSO_SHAPE.RECTANGLE,
                                   left, top, width, height)
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill_color
    if border_color:
        shape.line.color.rgb = border_color
        shape.line.width = Pt(1)
    else:
        shape.line.fill.background()
    return shape


def add_text_box(slide, left, top, width, height, text, font_size=18, color=WHITE, bold=False, alignment=PP_ALIGN.LEFT, font_name='Calibri'):
    txBox = slide.shapes.add_textbox(left, top, width, height)
    tf = txBox.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = text
    p.font.size = Pt(font_size)
    p.font.color.rgb = color
    p.font.bold = bold
    p.font.name = font_name
    p.alignment = alignment
    return txBox


def add_bullet_text(slide, left, top, width, height, items, font_size=16, color=WHITE, bullet_color=ACCENT_GOLD):
    txBox = slide.shapes.add_textbox(left, top, width, height)
    tf = txBox.text_frame
    tf.word_wrap = True
    for i, item in enumerate(items):
        if i == 0:
            p = tf.paragraphs[0]
        else:
            p = tf.add_paragraph()
        p.text = item
        p.font.size = Pt(font_size)
        p.font.color.rgb = color
        p.font.name = 'Calibri'
        p.space_after = Pt(8)
        p.level = 0
    return txBox


def add_accent_line(slide, left, top, width, color=ACCENT_GOLD):
    shape = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, left, top, width, Pt(3))
    shape.fill.solid()
    shape.fill.fore_color.rgb = color
    shape.line.fill.background()
    return shape


def add_metric_card(slide, left, top, width, height, label, value, accent=ACCENT_GOLD):
    card = add_shape(slide, left, top, width, height, CARD_BG, accent)
    add_text_box(slide, left + Inches(0.3), top + Inches(0.2), width - Inches(0.6), Inches(0.6),
                 value, font_size=28, color=accent, bold=True, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, left + Inches(0.3), top + Inches(0.8), width - Inches(0.6), Inches(0.5),
                 label, font_size=13, color=LIGHT_GRAY, alignment=PP_ALIGN.CENTER)
    return card


# ============================================================================
# SLIDE 1: TITLE SLIDE
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])  # Blank layout
set_slide_bg(slide, SLIDE_BG)

# Decorative accent bar at top
add_shape(slide, Inches(0), Inches(0), SLIDE_W, Pt(4), ACCENT_GOLD)

# Central content
add_text_box(slide, Inches(1.5), Inches(1.5), Inches(10), Inches(1.2),
             "EMERGE", font_size=72, color=WHITE, bold=True, alignment=PP_ALIGN.CENTER)

add_accent_line(slide, Inches(5), Inches(2.8), Inches(3.3), ACCENT_GOLD)

add_text_box(slide, Inches(2), Inches(3.2), Inches(9), Inches(0.8),
             "The Identity-First Habit Ecosystem", font_size=32, color=ACCENT_GOLD,
             bold=False, alignment=PP_ALIGN.CENTER)

add_text_box(slide, Inches(2), Inches(4.2), Inches(9), Inches(0.8),
             "Transforming who you are, one vote at a time.", font_size=20, color=LIGHT_GRAY,
             alignment=PP_ALIGN.CENTER)

# Bottom info
add_text_box(slide, Inches(2), Inches(5.8), Inches(9), Inches(0.5),
             "Investor Pitch Deck  •  2026", font_size=16, color=LIGHT_GRAY,
             alignment=PP_ALIGN.CENTER)

add_text_box(slide, Inches(2), Inches(6.3), Inches(9), Inches(0.5),
             "Flutter • Firebase • AI-Powered Behavioral Science", font_size=14,
             color=MID_PURPLE, alignment=PP_ALIGN.CENTER)


# ============================================================================
# SLIDE 2: THE PROBLEM
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "THE PROBLEM", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(8), Inches(0.9),
             "Habit Apps Are Broken. Here's Why.", font_size=36, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.9), Inches(2), ACCENT_CORAL)

# Problem cards
problems = [
    ("92%", "Failure Rate", "of people abandon New Year's\nresolutions by February"),
    ("95%", "Churn Rate", "of habit tracker users quit\nwithin the first 30 days"),
    ("₦0", "Real Value", "Most apps track outcomes,\nnot identity transformation"),
]

for i, (stat, title, desc) in enumerate(problems):
    x = Inches(0.8 + i * 4.0)
    y = Inches(2.5)
    card = add_shape(slide, x, y, Inches(3.5), Inches(2.8), CARD_BG, ACCENT_CORAL)
    add_text_box(slide, x + Inches(0.3), y + Inches(0.3), Inches(3), Inches(0.8),
                 stat, font_size=48, color=ACCENT_CORAL, bold=True, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, x + Inches(0.3), y + Inches(1.2), Inches(3), Inches(0.4),
                 title, font_size=18, color=WHITE, bold=True, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, x + Inches(0.3), y + Inches(1.7), Inches(3), Inches(1.0),
                 desc, font_size=13, color=LIGHT_GRAY, alignment=PP_ALIGN.CENTER)

add_text_box(slide, Inches(0.8), Inches(5.8), Inches(11), Inches(0.8),
             "The root cause: Current apps focus on OUTCOMES (\"I want to lose weight\") instead of IDENTITY (\"I am an athlete\").\n"
             "They neglect the deepest layer of behavior change — who you believe you are.",
             font_size=15, color=LIGHT_GRAY)


# ============================================================================
# SLIDE 3: THE SOLUTION
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "THE SOLUTION", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(10), Inches(0.9),
             "Emerge: Your Life as an RPG", font_size=36, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.9), Inches(2), ACCENT_GREEN)

add_text_box(slide, Inches(0.8), Inches(2.2), Inches(11), Inches(0.8),
             "Emerge is not a tracker — it's an Identity Engine.\n"
             "Built on the science of Atomic Habits, it transforms the invisible accumulation of small actions into a visible, gamified journey of self-transformation.",
             font_size=16, color=LIGHT_GRAY)

# Solution pillars
pillars = [
    ("🎭", "Identity-First", "Users don't set goals.\nThey choose who they\nwant to BECOME."),
    ("🏙️", "Living Worlds", "Cities grow & forests bloom\nwith every habit completed.\nDecay shows neglect."),
    ("🗳️", "Vote System", "Every habit is a \"vote\"\nfor your desired identity.\nEvidence, not willpower."),
    ("🤖", "AI Life Coach", "Gemini-powered coaching\nthat adapts difficulty\nand reinforces identity."),
]

for i, (icon, title, desc) in enumerate(pillars):
    x = Inches(0.8 + i * 3.1)
    y = Inches(3.5)
    card = add_shape(slide, x, y, Inches(2.8), Inches(3.2), CARD_BG, MID_PURPLE)
    add_text_box(slide, x + Inches(0.2), y + Inches(0.2), Inches(2.4), Inches(0.6),
                 icon, font_size=36, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, x + Inches(0.2), y + Inches(0.9), Inches(2.4), Inches(0.5),
                 title, font_size=18, color=ACCENT_GOLD, bold=True, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, x + Inches(0.2), y + Inches(1.5), Inches(2.4), Inches(1.5),
                 desc, font_size=13, color=LIGHT_GRAY, alignment=PP_ALIGN.CENTER)


# ============================================================================
# SLIDE 4: THE SCIENCE - FOUR LAWS OF BEHAVIOR CHANGE
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "THE SCIENCE", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(10), Inches(0.9),
             "Four Laws of Behavior Change → UX Architecture", font_size=32, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.9), Inches(2), ACCENT_CYAN)

laws = [
    ("1st LAW", "MAKE IT OBVIOUS", "Context-aware dashboards that change by time of day.\n"
     "Habit Stacking: \"After [coffee], I will [meditate].\"\n"
     "Home screen widgets keep cues visible.", ACCENT_CYAN),
    ("2nd LAW", "MAKE IT ATTRACTIVE", "Gamified identity layers with XP & leveling.\n"
     "Temptation Bundling: Lock rewards behind habits.\n"
     "Creator Blueprints from influencers.", ACCENT_GOLD),
    ("3rd LAW", "MAKE IT EASY", "Two-Minute Rule mode for every habit.\n"
     "One-tap logging, passive HealthKit tracking.\n"
     "Environment priming prompts.", ACCENT_GREEN),
    ("4th LAW", "MAKE IT SATISFYING", "Instant visual growth: cities build, forests bloom.\n"
     "Cinematic weekly/monthly recap videos.\n"
     "Streak protection with \"Never Miss Twice\" rule.", ACCENT_CORAL),
]

for i, (num, title, desc, color) in enumerate(laws):
    x = Inches(0.8 + (i % 2) * 6.2)
    y = Inches(2.3 + (i // 2) * 2.6)
    card = add_shape(slide, x, y, Inches(5.8), Inches(2.2), CARD_BG, color)

    add_text_box(slide, x + Inches(0.3), y + Inches(0.2), Inches(1.5), Inches(0.4),
                 num, font_size=12, color=color, bold=True)
    add_text_box(slide, x + Inches(0.3), y + Inches(0.5), Inches(5), Inches(0.4),
                 title, font_size=20, color=WHITE, bold=True)
    add_text_box(slide, x + Inches(0.3), y + Inches(1.0), Inches(5.2), Inches(1.2),
                 desc, font_size=12, color=LIGHT_GRAY)


# ============================================================================
# SLIDE 5: PRODUCT DEEP DIVE — ONBOARDING & IDENTITY
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "PRODUCT DEEP DIVE", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(10), Inches(0.9),
             "Onboarding: The RPG Character Creation Engine", font_size=32, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.85), Inches(2), ACCENT_GOLD)

# Left column - Future Self Studio
add_shape(slide, Inches(0.8), Inches(2.3), Inches(5.8), Inches(4.8), CARD_BG, MID_PURPLE)
add_text_box(slide, Inches(1.1), Inches(2.5), Inches(5), Inches(0.4),
             "🎨 The \"Future Self\" Studio", font_size=20, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(1.1), Inches(3.0), Inches(5.2), Inches(0.4),
             "We don't ask: \"What habits do you want to track?\"", font_size=14, color=LIGHT_GRAY)
add_text_box(slide, Inches(1.1), Inches(3.4), Inches(5.2), Inches(0.4),
             "We ask: \"Who do you wish to become?\"", font_size=18, color=WHITE, bold=True)

archetypes = [
    ("⚡ The Athlete", "Physical vitality, endurance, strength"),
    ("🎨 The Creator", "Output, deep work, expression"),
    ("📚 The Scholar", "Learning, reading, cognitive expansion"),
    ("🧘 The Stoic", "Mindfulness, emotional regulation"),
    ("🌍 The Explorer", "Adventure, curiosity, growth"),
    ("🔥 The Zealot", "Passion, discipline, intensity"),
]

for i, (name, desc) in enumerate(archetypes):
    y_pos = Inches(4.0 + i * 0.45)
    add_text_box(slide, Inches(1.3), y_pos, Inches(2.5), Inches(0.4),
                 name, font_size=13, color=ACCENT_CYAN, bold=True)
    add_text_box(slide, Inches(3.6), y_pos, Inches(3), Inches(0.4),
                 desc, font_size=12, color=LIGHT_GRAY)

# Right column - Habit Stacking
add_shape(slide, Inches(7.0), Inches(2.3), Inches(5.5), Inches(4.8), CARD_BG, MID_PURPLE)
add_text_box(slide, Inches(7.3), Inches(2.5), Inches(5), Inches(0.4),
             "🔗 Habit Stack Builder", font_size=20, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(7.3), Inches(3.0), Inches(5), Inches(0.6),
             "Visual drag-and-drop programming of daily routines.\n"
             "Anchored to existing behaviors for maximum adherence.",
             font_size=14, color=LIGHT_GRAY)

stack_items = [
    ("ANCHOR:", "☕ Pour Coffee", "Existing habit (bedrock)"),
    ("STACK:", "🧘 Meditate 2 min", "New habit (snaps on top)"),
    ("STACK:", "📝 Journal 1 page", "Identity: Writer"),
    ("STACK:", "💪 10 Push-ups", "Identity: Athlete"),
]

for i, (tag, action, note) in enumerate(stack_items):
    y_pos = Inches(3.9 + i * 0.7)
    accent = ACCENT_CYAN if tag == "ANCHOR:" else ACCENT_GREEN
    add_shape(slide, Inches(7.3), y_pos, Inches(4.9), Inches(0.55), 
              RGBColor(0x15, 0x0F, 0x2E), accent)
    add_text_box(slide, Inches(7.5), y_pos + Inches(0.05), Inches(1.2), Inches(0.4),
                 tag, font_size=10, color=accent, bold=True)
    add_text_box(slide, Inches(8.6), y_pos + Inches(0.05), Inches(1.8), Inches(0.4),
                 action, font_size=13, color=WHITE, bold=True)
    add_text_box(slide, Inches(10.5), y_pos + Inches(0.05), Inches(1.5), Inches(0.4),
                 note, font_size=10, color=LIGHT_GRAY)


# ============================================================================
# SLIDE 6: DYNAMIC VISUAL PROGRESSION — THE SECRET SAUCE
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "THE SECRET SAUCE", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(10), Inches(0.9),
             "Dynamic Visual Progression: See Your Life Transform", font_size=32, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.85), Inches(2), ACCENT_GREEN)

# Avatar System
add_shape(slide, Inches(0.8), Inches(2.3), Inches(3.8), Inches(4.8), CARD_BG, MID_PURPLE)
add_text_box(slide, Inches(1.1), Inches(2.5), Inches(3.3), Inches(0.4),
             "🦸 Avatar System", font_size=20, color=ACCENT_GOLD, bold=True)
add_bullet_text(slide, Inches(1.1), Inches(3.1), Inches(3.3), Inches(3.5), [
    "→ Morphs based on real habits",
    "→ Strength habits → muscle definition",
    "→ Intellect habits → focus aura",
    "→ Vitality habits → glow effects",
    "→ Equipment unlocked via identity",
    "  votes, NOT purchases",
    "→ 6 archetype-based avatar paths",
], font_size=13)

# Living City
add_shape(slide, Inches(4.9), Inches(2.3), Inches(3.8), Inches(4.8), CARD_BG, MID_PURPLE)
add_text_box(slide, Inches(5.2), Inches(2.5), Inches(3.3), Inches(0.4),
             "🏙️ The Living City", font_size=20, color=ACCENT_CYAN, bold=True)
add_bullet_text(slide, Inches(5.2), Inches(3.1), Inches(3.3), Inches(3.5), [
    "→ Deep Work → builds skyscrapers",
    "→ Social habits → parks & bridges",
    "→ Financial habits → infrastructure",
    "→ \"Perfect Day\" → festival events!",
    "",
    "DECAY MECHANICS:",
    "→ Miss 3 days: weeds, overcast sky",
    "→ One action lifts the fog instantly",
], font_size=13)

# Evolving Forest
add_shape(slide, Inches(9.0), Inches(2.3), Inches(3.8), Inches(4.8), CARD_BG, MID_PURPLE)
add_text_box(slide, Inches(9.3), Inches(2.5), Inches(3.3), Inches(0.4),
             "🌲 The Evolving Forest", font_size=20, color=ACCENT_GREEN, bold=True)
add_bullet_text(slide, Inches(9.3), Inches(3.1), Inches(3.3), Inches(3.5), [
    "→ Meditation → plants ancient trees",
    "→ Hydration → fills rivers & lakes",
    "→ Exercise → fauna appear",
    "→ Streaks → \"Superbloom\" events!",
    "",
    "WORLD THEMES:",
    "→ Pro users select custom themes",
    "→ Procedural generation via Flame",
], font_size=13)


# ============================================================================
# SLIDE 7: MARKET OPPORTUNITY
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "MARKET OPPORTUNITY", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(10), Inches(0.9),
             "A ₦18+ Trillion Global Market, Grossly Underserved", font_size=32, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.85), Inches(2), ACCENT_GOLD)

# Market size cards
add_metric_card(slide, Inches(0.8), Inches(2.3), Inches(3.6), Inches(1.3),
                "Global Habit Tracker Market (2025)", "₦17.6 Trillion", ACCENT_GOLD)
add_metric_card(slide, Inches(4.8), Inches(2.3), Inches(3.6), Inches(1.3),
                "Projected by 2035 (14.4% CAGR)", "₦67.8 Trillion", ACCENT_CYAN)
add_metric_card(slide, Inches(8.8), Inches(2.3), Inches(3.8), Inches(1.3),
                "Nigeria Digital Health Market", "₦2 Trillion+", ACCENT_GREEN)

# Nigeria specific opportunity
add_shape(slide, Inches(0.8), Inches(4.0), Inches(5.8), Inches(3.2), CARD_BG, MID_PURPLE)
add_text_box(slide, Inches(1.1), Inches(4.2), Inches(5.3), Inches(0.4),
             "🇳🇬 Nigeria: The Untapped Goldmine", font_size=20, color=ACCENT_GOLD, bold=True)
add_bullet_text(slide, Inches(1.1), Inches(4.8), Inches(5.3), Inches(2.5), [
    "→ 120M+ smartphone users (15% annual growth)",
    "→ Online Fitness market: ₦209B → ₦2T by 2033 (29% CAGR)",
    "→ Mental Wellness market: ₦383B by 2033 (9.8% CAGR)",
    "→ ZERO identity-first habit apps in the market",
    "→ Young population: 60%+ under 25, digital-native",
    "→ Growing middle class embracing self-improvement",
], font_size=14)

# Global context
add_shape(slide, Inches(7.0), Inches(4.0), Inches(5.8), Inches(3.2), CARD_BG, MID_PURPLE)
add_text_box(slide, Inches(7.3), Inches(4.2), Inches(5.3), Inches(0.4),
             "🌍 Global Competitive Landscape", font_size=20, color=ACCENT_CYAN, bold=True)
add_bullet_text(slide, Inches(7.3), Inches(4.8), Inches(5.3), Inches(2.5), [
    "→ Habitica: Gamified but no identity layer",
    "→ Streaks: Simple but no social/visual world",
    "→ Fabulous: Beautiful but subscription-locked basics",
    "→ Forest: Single metaphor, no identity engine",
    "→ NONE combine: Identity + Worlds + AI + Social",
    "→ Emerge is the FIRST identity-first ecosystem",
], font_size=14)


# ============================================================================
# SLIDE 8: PREMIUM MONETIZATION MODEL
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "MONETIZATION", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(10), Inches(0.9),
             "Emerge Pro: Premium Model Built for Nigeria", font_size=32, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.85), Inches(2), ACCENT_GOLD)

# Pricing cards
pricing = [
    ("MONTHLY", "₦2,500/mo", "~$1.85 USD\nAffordable entry point\nbelow Spotify Nigeria", ACCENT_CYAN),
    ("ANNUAL", "₦20,000/yr", "~$14.80 USD\nSave ₦10,000 (33% off)\n4 months FREE", ACCENT_GOLD),
    ("LIFETIME", "₦65,000", "~$48.15 USD\nOne-time purchase\nForever premium access", ACCENT_GREEN),
]

for i, (plan, price, desc, accent) in enumerate(pricing):
    x = Inches(0.8 + i * 4.2)
    card = add_shape(slide, x, Inches(2.3), Inches(3.8), Inches(2.2), CARD_BG, accent)
    add_text_box(slide, x + Inches(0.2), Inches(2.45), Inches(3.4), Inches(0.3),
                 plan, font_size=12, color=accent, bold=True, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, x + Inches(0.2), Inches(2.8), Inches(3.4), Inches(0.6),
                 price, font_size=32, color=WHITE, bold=True, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, x + Inches(0.2), Inches(3.5), Inches(3.4), Inches(0.9),
                 desc, font_size=12, color=LIGHT_GRAY, alignment=PP_ALIGN.CENTER)

# Feature comparison
add_shape(slide, Inches(0.8), Inches(4.8), Inches(11.7), Inches(2.5), CARD_BG, MID_PURPLE)
add_text_box(slide, Inches(1.1), Inches(4.9), Inches(4), Inches(0.4),
             "Feature Comparison", font_size=18, color=WHITE, bold=True)

# Headers
add_text_box(slide, Inches(1.1), Inches(5.35), Inches(4), Inches(0.3),
             "Feature", font_size=12, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(6.5), Inches(5.35), Inches(2.5), Inches(0.3),
             "Free Tier", font_size=12, color=ACCENT_GOLD, bold=True, alignment=PP_ALIGN.CENTER)
add_text_box(slide, Inches(9.5), Inches(5.35), Inches(2.5), Inches(0.3),
             "Emerge Pro ✨", font_size=12, color=ACCENT_GOLD, bold=True, alignment=PP_ALIGN.CENTER)

features = [
    ("Active Habits", "3 Max", "Unlimited"),
    ("Habit Stacks", "1 Morning Stack", "Unlimited (AM/PM/Night)"),
    ("Analytics", "Current Streak", "Heatmaps, Trends, %"),
    ("Avatar/World", "Basic Avatar", "Pro Skins, Auras, Pets"),
    ("AI Coach", "Basic Chat", "Full History Analysis"),
    ("Ads", "Banner Ads", "Ad-Free ✨"),
]

for i, (feature, free, pro) in enumerate(features):
    y_pos = Inches(5.65 + i * 0.25)
    color = LIGHT_GRAY if i % 2 == 0 else SOFT_WHITE
    add_text_box(slide, Inches(1.1), y_pos, Inches(4), Inches(0.25),
                 feature, font_size=11, color=LIGHT_GRAY)
    add_text_box(slide, Inches(6.5), y_pos, Inches(2.5), Inches(0.25),
                 free, font_size=11, color=LIGHT_GRAY, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, Inches(9.5), y_pos, Inches(2.5), Inches(0.25),
                 pro, font_size=11, color=ACCENT_GOLD, alignment=PP_ALIGN.CENTER)


# ============================================================================
# SLIDE 9: REVENUE PROJECTIONS
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "REVENUE PROJECTIONS", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(10), Inches(0.9),
             "Path to ₦1 Billion Annual Revenue", font_size=32, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.85), Inches(2), ACCENT_GOLD)

# Revenue streams
add_shape(slide, Inches(0.8), Inches(2.3), Inches(7.5), Inches(4.8), CARD_BG, MID_PURPLE)
add_text_box(slide, Inches(1.1), Inches(2.5), Inches(7), Inches(0.4),
             "📊 3-Year Revenue Model (Conservative)", font_size=18, color=ACCENT_GOLD, bold=True)

# Year headers
years_data = [
    ("METRIC", "Year 1", "Year 2", "Year 3"),
    ("Total Users", "50,000", "250,000", "1,000,000"),
    ("Premium Conv. Rate", "3%", "5%", "7%"),
    ("Premium Users", "1,500", "12,500", "70,000"),
    ("Avg Revenue/User", "₦2,500/mo", "₦2,200/mo", "₦2,000/mo"),
    ("Subscription Rev.", "₦45M", "₦330M", "₦1.68B"),
    ("Ad Revenue", "₦15M", "₦95M", "₦372M"),
    ("Consumables", "₦5M", "₦25M", "₦100M"),
    ("TOTAL REVENUE", "₦65M", "₦450M", "₦2.15B"),
]

for i, row in enumerate(years_data):
    y_pos = Inches(3.0 + i * 0.42)
    is_header = i == 0
    is_total = i == len(years_data) - 1
    color = ACCENT_GOLD if is_header or is_total else LIGHT_GRAY
    font_b = is_header or is_total

    add_text_box(slide, Inches(1.2), y_pos, Inches(2.2), Inches(0.35),
                 row[0], font_size=12, color=color, bold=font_b)
    add_text_box(slide, Inches(3.5), y_pos, Inches(1.5), Inches(0.35),
                 row[1], font_size=12, color=color, bold=font_b, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, Inches(5.0), y_pos, Inches(1.5), Inches(0.35),
                 row[2], font_size=12, color=color, bold=font_b, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, Inches(6.5), y_pos, Inches(1.5), Inches(0.35),
                 row[3], font_size=12, color=color, bold=font_b, alignment=PP_ALIGN.CENTER)

# Revenue streams breakdown
add_shape(slide, Inches(8.8), Inches(2.3), Inches(3.8), Inches(4.8), CARD_BG, MID_PURPLE)
add_text_box(slide, Inches(9.1), Inches(2.5), Inches(3.3), Inches(0.4),
             "💰 Revenue Streams", font_size=18, color=ACCENT_GOLD, bold=True)

streams = [
    ("Subscriptions", "78%", "Monthly, Annual & Lifetime\npremium subscriptions", ACCENT_GOLD),
    ("Advertising", "17%", "Banner & interstitial ads\nfor free-tier users", ACCENT_CYAN),
    ("Consumables", "5%", "Streak freezes, premium\nthemes, avatar items", ACCENT_GREEN),
]

for i, (name, pct, desc, accent) in enumerate(streams):
    y_pos = Inches(3.1 + i * 1.3)
    add_shape(slide, Inches(9.1), y_pos, Inches(3.3), Inches(1.1), 
              RGBColor(0x15, 0x0F, 0x2E), accent)
    add_text_box(slide, Inches(9.3), y_pos + Inches(0.1), Inches(1.8), Inches(0.3),
                 name, font_size=14, color=WHITE, bold=True)
    add_text_box(slide, Inches(11.3), y_pos + Inches(0.1), Inches(0.8), Inches(0.3),
                 pct, font_size=14, color=accent, bold=True, alignment=PP_ALIGN.RIGHT)
    add_text_box(slide, Inches(9.3), y_pos + Inches(0.45), Inches(2.8), Inches(0.6),
                 desc, font_size=10, color=LIGHT_GRAY)


# ============================================================================
# SLIDE 10: WHAT EMERGE HAS BUILT (CURRENT STATE)
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "TRACTION & PROGRESS", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(10), Inches(0.9),
             "What We've Already Built", font_size=32, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.85), Inches(2), ACCENT_GREEN)

# Built features - left column
add_shape(slide, Inches(0.8), Inches(2.2), Inches(5.8), Inches(5.0), CARD_BG, ACCENT_GREEN)
add_text_box(slide, Inches(1.1), Inches(2.4), Inches(5.3), Inches(0.4),
             "✅ Production-Ready Features", font_size=18, color=ACCENT_GREEN, bold=True)

built_features = [
    "✅ Full Auth System (Firebase Auth + Google Sign-In)",
    "✅ Identity Onboarding (6 Archetypes + Future Self Studio)",
    "✅ Core Habit Engine (Create, Stack, Complete, Streaks)",
    "✅ Dynamic Timeline Dashboard (Morning/Noon/Night)",
    "✅ RPG Gamification (XP, Levels, Identity Votes)",
    "✅ Living World Visualizer (Flame engine, City + Forest)",
    "✅ AI Life Coach (Gemini-powered, context-aware)",
    "✅ Social Tribes & Community Features",
    "✅ Monetization (RevenueCat + AdMob integrated)",
    "✅ Tutorial System (Identity-first onboarding)",
    "✅ Home Screen Widgets (Cue visibility)",
    "✅ Cross-platform (Android, Web, Windows)",
    "✅ Firebase Crashlytics, Analytics, Remote Config",
    "✅ Cinematic Progress Recaps & Social Sharing",
]

for i, feature in enumerate(built_features):
    add_text_box(slide, Inches(1.1), Inches(2.9 + i * 0.28), Inches(5.3), Inches(0.28),
                 feature, font_size=11, color=WHITE if "✅" in feature else LIGHT_GRAY)

# Tech stack
add_shape(slide, Inches(7.0), Inches(2.2), Inches(5.5), Inches(5.0), CARD_BG, ACCENT_CYAN)
add_text_box(slide, Inches(7.3), Inches(2.4), Inches(5), Inches(0.4),
             "⚙️ Tech Stack & Architecture", font_size=18, color=ACCENT_CYAN, bold=True)

tech_items = [
    ("Framework", "Flutter 3.10+ (Impeller)"),
    ("Language", "Dart 3.5+ (Strict Null Safety)"),
    ("State Mgmt", "Riverpod v3 (Code Gen)"),
    ("Backend", "Firebase Gen 2 (Full Suite)"),
    ("AI Engine", "Firebase AI / Gemini"),
    ("Game Engine", "Flame (Procedural Worlds)"),
    ("Payments", "RevenueCat SDK"),
    ("Ads", "Google AdMob"),
    ("Navigation", "GoRouter (Deep Linking)"),
    ("Storage", "Hive (Offline-First)"),
    ("Notifications", "FCM + Local"),
    ("Health Data", "HealthKit/Google Fit"),
    ("Architecture", "Clean Architecture"),
    ("Version", "v1.0.3 (Production)"),
]

for i, (label, value) in enumerate(tech_items):
    y_pos = Inches(2.9 + i * 0.30)
    add_text_box(slide, Inches(7.3), y_pos, Inches(2.0), Inches(0.28),
                 label, font_size=11, color=ACCENT_CYAN, bold=True)
    add_text_box(slide, Inches(9.3), y_pos, Inches(3.0), Inches(0.28),
                 value, font_size=11, color=WHITE)


# ============================================================================
# SLIDE 11: WHAT EMERGE NEEDS — NEXT LEVEL
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "GROWTH ROADMAP", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(10), Inches(0.9),
             "What Emerge Needs to Reach the Next Level", font_size=32, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.85), Inches(2), ACCENT_CORAL)

# Phase cards
phases = [
    ("PHASE 1: FOUNDATION", "Q2 2026", [
        "iOS App Store launch",
        "Production RevenueCat setup",
        "App Store Optimization (ASO)",
        "Performance optimization",
        "Automated testing suite",
        "Crashlytics monitoring",
    ], ACCENT_CYAN, "₦15M"),
    ("PHASE 2: GROWTH", "Q3-Q4 2026", [
        "Wearable integrations (Apple Watch, Fitbit)",
        "AR Mirror feature (avatar overlay)",
        "Creator Blueprint marketplace",
        "Advanced AI coaching (full history)",
        "Sponsored challenges partnerships",
        "Referral & viral loop system",
    ], ACCENT_GOLD, "₦35M"),
    ("PHASE 3: SCALE", "2027", [
        "Family/Corporate Tribe plans",
        "Real-world brand partnerships (Nike, etc.)",
        "Habit Contract staking system",
        "International expansion (Francophone Africa)",
        "Metaverse integrations",
        "Series A fundraise",
    ], ACCENT_GREEN, "₦50M"),
]

for i, (title, timeline, items, accent, budget) in enumerate(phases):
    x = Inches(0.8 + i * 4.1)
    card = add_shape(slide, x, Inches(2.2), Inches(3.7), Inches(4.8), CARD_BG, accent)
    add_text_box(slide, x + Inches(0.2), Inches(2.35), Inches(3.3), Inches(0.3),
                 title, font_size=14, color=accent, bold=True)
    add_text_box(slide, x + Inches(0.2), Inches(2.65), Inches(3.3), Inches(0.3),
                 timeline, font_size=12, color=LIGHT_GRAY)

    for j, item in enumerate(items):
        add_text_box(slide, x + Inches(0.2), Inches(3.1 + j * 0.38), Inches(3.3), Inches(0.35),
                     f"→ {item}", font_size=11, color=WHITE)

    # Budget tag
    add_shape(slide, x + Inches(0.5), Inches(6.4), Inches(2.7), Inches(0.4), 
              RGBColor(0x15, 0x0F, 0x2E), accent)
    add_text_box(slide, x + Inches(0.5), Inches(6.4), Inches(2.7), Inches(0.4),
                 f"Investment: {budget}", font_size=12, color=accent, bold=True, alignment=PP_ALIGN.CENTER)


# ============================================================================
# SLIDE 12: THE ASK — FUNDING
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "THE ASK", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(10), Inches(0.9),
             "Pre-Seed: ₦100 Million", font_size=40, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.9), Inches(2), ACCENT_GOLD)

add_text_box(slide, Inches(0.8), Inches(2.2), Inches(11), Inches(0.5),
             "To accelerate from MVP to market dominance in the identity-first habit space.",
             font_size=16, color=LIGHT_GRAY)

# Fund allocation
allocations = [
    ("Engineering & Product", "40%", "₦40M", "iOS launch, Wearable integrations, AR features, AI coaching"),
    ("Marketing & Growth", "30%", "₦30M", "ASO, Influencer partnerships, Creator onboarding, Social media"),
    ("Operations & Team", "20%", "₦20M", "Key hires (Designer, Backend Engineer, Community Manager)"),
    ("Legal & Infrastructure", "10%", "₦10M", "IP protection, Cloud infrastructure, Compliance"),
]

for i, (category, pct, amount, desc) in enumerate(allocations):
    y = Inches(2.9 + i * 1.1)
    accent = [ACCENT_CYAN, ACCENT_GOLD, ACCENT_GREEN, ACCENT_CORAL][i]
    card = add_shape(slide, Inches(0.8), y, Inches(11.7), Inches(0.9), CARD_BG, accent)

    add_text_box(slide, Inches(1.2), y + Inches(0.1), Inches(3.5), Inches(0.35),
                 category, font_size=16, color=WHITE, bold=True)
    add_text_box(slide, Inches(4.8), y + Inches(0.1), Inches(0.8), Inches(0.35),
                 pct, font_size=18, color=accent, bold=True, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, Inches(5.8), y + Inches(0.1), Inches(1.5), Inches(0.35),
                 amount, font_size=16, color=accent, bold=True)
    add_text_box(slide, Inches(7.5), y + Inches(0.1), Inches(4.5), Inches(0.7),
                 desc, font_size=12, color=LIGHT_GRAY)

# Key metrics
add_text_box(slide, Inches(0.8), Inches(6.0), Inches(11), Inches(0.4),
             "Target Milestones (18 Months Post-Funding)", font_size=16, color=WHITE, bold=True)

milestones = [
    ("250K", "Total Users"),
    ("5%", "Premium Conv."),
    ("₦450M", "Annual Revenue"),
    ("4.5★", "App Store Rating"),
]

for i, (value, label) in enumerate(milestones):
    x = Inches(0.8 + i * 3.1)
    add_metric_card(slide, x, Inches(6.4), Inches(2.8), Inches(1.1), label, value, ACCENT_GOLD)


# ============================================================================
# SLIDE 13: COMPETITIVE MOAT & WHY NOW
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_text_box(slide, Inches(0.8), Inches(0.5), Inches(5), Inches(0.6),
             "COMPETITIVE MOAT", font_size=14, color=ACCENT_GOLD, bold=True)
add_text_box(slide, Inches(0.8), Inches(1.0), Inches(10), Inches(0.9),
             "Why Emerge. Why Now. Why Nigeria.", font_size=36, color=WHITE, bold=True)
add_accent_line(slide, Inches(0.8), Inches(1.85), Inches(2), ACCENT_GOLD)

# Moat items
moats = [
    ("🧬", "IDENTITY-FIRST IP", "The only app built on identity-based behavioral science.\n"
     "Not a feature — it's the entire architecture.", ACCENT_GOLD),
    ("🎮", "PROCEDURAL WORLDS", "Flame-engine living cities & forests create emotional\n"
     "attachment impossible to replicate quickly.", ACCENT_CYAN),
    ("🤖", "AI COACHING LOOP", "Gemini integration creates personalized coaching that\n"
     "improves with every interaction. Network effects.", ACCENT_GREEN),
    ("🌍", "AFRICA-FIRST", "Built for African markets first — Naira pricing, offline-first,\n"
     "low-bandwidth optimized. Then scale globally.", ACCENT_CORAL),
]

for i, (icon, title, desc, accent) in enumerate(moats):
    x = Inches(0.8 + (i % 2) * 6.3)
    y = Inches(2.2 + (i // 2) * 2.6)
    card = add_shape(slide, x, y, Inches(5.8), Inches(2.2), CARD_BG, accent)
    add_text_box(slide, x + Inches(0.3), y + Inches(0.2), Inches(0.6), Inches(0.5),
                 icon, font_size=28)
    add_text_box(slide, x + Inches(1.0), y + Inches(0.2), Inches(4.5), Inches(0.4),
                 title, font_size=18, color=accent, bold=True)
    add_text_box(slide, x + Inches(1.0), y + Inches(0.7), Inches(4.5), Inches(1.3),
                 desc, font_size=13, color=LIGHT_GRAY)


# ============================================================================
# SLIDE 14: CLOSING — CALL TO ACTION
# ============================================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
set_slide_bg(slide, SLIDE_BG)

add_shape(slide, Inches(0), Inches(0), SLIDE_W, Pt(4), ACCENT_GOLD)

add_text_box(slide, Inches(2), Inches(1.2), Inches(9.3), Inches(1.0),
             "EMERGE", font_size=64, color=WHITE, bold=True, alignment=PP_ALIGN.CENTER)

add_accent_line(slide, Inches(5), Inches(2.3), Inches(3.3), ACCENT_GOLD)

add_text_box(slide, Inches(2), Inches(2.8), Inches(9.3), Inches(0.6),
             "Tiny changes. Remarkable results.",
             font_size=28, color=ACCENT_GOLD, alignment=PP_ALIGN.CENTER)

add_text_box(slide, Inches(2.5), Inches(3.6), Inches(8.3), Inches(1.5),
             "Emerge transforms the invisible accumulation of habits into a visible,\n"
             "gamified journey of self-transformation. We don't just track what you do.\n"
             "We help you become who you want to be.",
             font_size=18, color=LIGHT_GRAY, alignment=PP_ALIGN.CENTER)

# Contact info card
add_shape(slide, Inches(3.5), Inches(5.2), Inches(6.3), Inches(1.8), CARD_BG, ACCENT_GOLD)
add_text_box(slide, Inches(3.8), Inches(5.4), Inches(5.7), Inches(0.4),
             "Let's Build the Future of Self-Improvement Together",
             font_size=16, color=ACCENT_GOLD, bold=True, alignment=PP_ALIGN.CENTER)
add_text_box(slide, Inches(3.8), Inches(5.9), Inches(5.7), Inches(0.9),
             "🌐  emergeapp.io\n"
             "📧  hello@emergeapp.io\n"
             "Built with ❤️ from Nigeria, for the World",
             font_size=14, color=LIGHT_GRAY, alignment=PP_ALIGN.CENTER)


# ============================================================================
# SAVE
# ============================================================================
output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Emerge_Pitch_Deck.pptx")
prs.save(output_path)
print(f"[OK] Pitch deck saved to: {output_path}")
print(f"[INFO] Total slides: {len(prs.slides)}")
