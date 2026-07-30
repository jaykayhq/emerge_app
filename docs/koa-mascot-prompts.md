# Koa Mascot — AI Image Generation Prompts

Use these prompts with DALL-E, Midjourney, Stable Diffusion, or similar tools.

---

## 1. Base Mascot (Neutral Expression)

### DALL-E / ChatGPT Prompt

```
Create a cute, friendly cartoon turtle mascot for a mobile app called "Emerge". 
The turtle should be:

Style: Modern flat design, rounded shapes, minimal detail, vector art style
Colors: 
- Shell: Deep purple (#1A0A2A) with teal (#2BEE79) and blue (#A5E7FF) nebula-like swirls
- Body: Dark purple (#2A1A3A)
- Eyes: Large, white with glowing teal iris
- Cheeks: Soft coral blush (#FF8E72)

Design:
- Standing upright on two legs (anthropomorphic)
- Large head (40% of body) with big expressive eyes
- Rounded shell with cosmic/nebula pattern (swirls, not realistic)
- Short, stubby limbs
- Friendly, warm expression
- Clean vector outlines (#0A0A1A, 2px)
- Transparent background

Expression: Neutral - relaxed pose, gentle half-smile
Size: Square format, mascot centered
```

### Midjourney Prompt

```
cute cartoon turtle mascot, standing upright, flat design, vector art style, 
large head with big expressive eyes, rounded shell with purple and teal nebula swirls, 
dark purple body, glowing teal iris, friendly expression, transparent background, 
mobile app mascot, modern minimal design --ar 1:1 --style raw --v 6
```

---

## 2. Expression Variants

### Happy Expression

```
Create a happy expression variant of a cute cartoon turtle mascot.
Same base design as above, but:
- Eyes sparkle with excitement
- Gentle smile (upward curved mouth)
- Slight head tilt
- Teal glow on shell intensifies
- Warm, celebratory feeling
Transparent background.
```

### Excited Expression

```
Create an excited expression variant of a cute cartoon turtle mascot.
Same base design, but:
- Wide eyes with golden iris (#FFD700)
- Big open smile
- Arms raised in celebration
- Shell glows brightly
- Energetic, triumphant feeling
Transparent background.
```

### Sad Expression

```
Create a sad expression variant of a cute cartoon turtle mascot.
Same base design, but:
- Downturned mouth
- Droopy eyes with gray iris (#90A4AE)
- Shell slightly dimmed
- Head tilted down
- Empathetic, not dramatic sadness
Transparent background.
```

### Sleepy Expression

```
Create a sleepy expression variant of a cute cartoon turtle mascot.
Same base design, but:
- Half-closed eyes (eyelids at 50%)
- Small "o" shaped mouth (yawning)
- "Zzz" particles near head
- Relaxed posture
- Peaceful, restful feeling
Transparent background.
```

### Encouraging Expression

```
Create an encouraging expression variant of a cute cartoon turtle mascot.
Same base design, but:
- Warm smile
- Head slightly tilted
- One arm extended (beckoning)
- Warm teal glow
- Supportive, welcoming feeling
Transparent background.
```

### Proud Expression

```
Create a proud expression variant of a cute cartoon turtle mascot.
Same base design, but:
- Chest puffed out
- Arms crossed or hands on hips
- Confident smile
- Shell radiating bright light
- Golden iris (#FFD700)
- Triumphant, accomplished feeling
Transparent background.
```

---

## 3. Archetype Shell Variants

### Athlete Shell

```
Recolor the turtle mascot's shell to red (#FF5252) with coral (#FF8E72) flame-like patterns. 
Add subtle flame/energy lines on the shell. Keep the same base design and body color.
Transparent background.
```

### Scholar Shell

```
Recolor the turtle mascot's shell to purple (#7C3AED) with lavender (#B794F6) star chart patterns. 
Add constellation-like dots and lines on the shell. Keep the same base design and body color.
Transparent background.
```

### Creator Shell

```
Recolor the turtle mascot's shell to gold (#FFD700) with yellow (#FFD93D) paint splatter accents. 
Add creative sparkles on the shell. Keep the same base design and body color.
Transparent background.
```

### Stoic Shell

```
Recolor the turtle mascot's shell to teal (#26A69A) with mint (#4DD4AC) zen garden patterns. 
Add serene mist/cloud effects on the shell. Keep the same base design and body color.
Transparent background.
```

### Zealot Shell

```
Recolor the turtle mascot's shell to crimson (#991B1B) with ember (#B45309) flame aura. 
Add intense glow and flame effects on the shell. Keep the same base design and body color.
Transparent background.
```

### Explorer Shell (Default)

```
Recolor the turtle mascot's shell to teal (#009688) with cyan (#64FFDA) compass rose patterns. 
Add map-like contour lines on the shell. Keep the same base design and body color.
Transparent background.
```

---

## 4. App Icon Variants

### App Icon (1024×1024)

```
Create a square app icon featuring a cute cartoon turtle mascot face (head only).
The turtle has:
- Large round head with big glowing teal eyes
- Purple shell visible behind head
- Cosmic/nebula background (#0A0A1A to #1A0A2A gradient)
- Subtle teal glow around the head
- Clean, minimal design
- No text
Size: 1024x1024 pixels
```

### Notification Icon (96×96)

```
Create a small notification icon of a cute cartoon turtle mascot face.
Minimal design, high contrast:
- White outline of turtle head
- Glowing teal eye
- Dark background
- Recognizable at small sizes
Size: 96x96 pixels
```

---

## 5. Lottie Animation Keyframes

For animated versions, describe the keyframes:

### Idle Breathing Animation

```
Frame 1: Scale 1.0
Frame 30: Scale 1.03
Frame 60: Scale 1.0
Loop: Continuous
Easing: Ease-in-out
```

### Happy Bounce Animation

```
Frame 1: Scale 1.0, Y: 0
Frame 10: Scale 1.15, Y: -10
Frame 20: Scale 1.0, Y: 0
Frame 25: Scale 1.05, Y: -3
Frame 30: Scale 1.0, Y: 0
Duration: 500ms
```

### Expression Transition

```
Frame 1: Previous expression
Frame 10: Scale 0.9 (slight shrink)
Frame 15: Neutral face
Frame 25: New expression, Scale 1.0
Duration: 300ms
```

---

## 6. Usage Guidelines

### Do's

✅ Use the mascot consistently across all touchpoints
✅ Match shell color to user's archetype
✅ Use appropriate expression for context
✅ Keep the mascot visible at all sizes (32px to billboard)
✅ Maintain the cosmic/nebula aesthetic

### Don'ts

❌ Don't add realistic textures (keep it flat/vector)
❌ Don't use bright white backgrounds
❌ Don't stretch or distort the proportions
❌ Don't add accessories not in the spec
❌ Don't change the eye glow color (always teal unless sad/excited)

---

## 7. File Naming Convention

```
assets/mascot/
  koa_neutral_explorer.png
  koa_happy_explorer.png
  koa_excited_explorer.png
  koa_sad_explorer.png
  koa_sleepy_explorer.png
  koa_encouraging_explorer.png
  koa_proud_explorer.png
  
  koa_neutral_athlete.png
  koa_neutral_scholar.png
  koa_neutral_creator.png
  koa_neutral_stoic.png
  koa_neutral_zealot.png
  
  koa_icon_1024.png
  koa_icon_512.png
  koa_icon_256.png
  koa_icon_128.png
  koa_icon_64.png
  koa_icon_32.png
  
  koa_notification_96.png
  
  koa_idle.json (Lottie)
  koa_happy.json (Lottie)
  koa_sad.json (Lottie)
```

---

**Document Version:** 1.0
**Last Updated:** 2026-07-28
