# World Map Immersive Portal Redesign

## Overview
Rebuilding the World Map screen to create an immersive, gamified experience bridging the Timeline and individual Attribute Details. The goal is to reinforce the user's habit loop and psychological identity through high-fidelity visual representations of entropy (cracks) and health (glow).

## Architecture & Components
1. **Routing Flow (Timeline -> World Map -> Attribute Screen)**
   - Introduce a Hero or PageRouteBuilder transition from clicking a Habit on the `TimelineScreen`.
   - The transition targets the World Map screen, bringing the world map into immediate focus.

2. **3D Orb Component (`CentralHealthOrb`)**
   - **Shader Implementation:** Replace the gradient `Container` with a `CustomPaint` widget running a GLSL Fragment Shader (`FragmentProgram`). 
   - **Visuals:** Render a 3D-looking sphere that exhibits cracks and a glowing core. Cracks recede (or glow intensifies) as health approaches maximum, and multiply as entropy increases.
   - **Interactivity:** Wrap the orb in a `GestureDetector`. Use `onPanUpdate` to feed X/Y coordinates into the shader, allowing the user to rotate the orb.
   - **Easter Egg:** A tap counter tracking rapid taps. At 7 taps, it triggers an interactive mini-game or visual explosion effect.

3. **Attribute Nodes (`WorldTypeNode` / `WorldRingLayout`)**
   - **3D Styling:** Redesign `WorldTypeNode` from a simple bordered circle to a 3D-styled floating node.
   - **Colors and Labels:** Ensure the node prominently displays the `primaryColor` mapping on the icon/background itself, rather than just the border. Ensure the `attributeName` is clearly legible and properly themed.
   - **Transition:** When an attribute node is tapped, run an animation to pull the node to the center (pushing the orb to the background) before navigating to the `AttributeDetailScreen`.

4. **Performance**
   - Ensure the shader doesn't block the UI thread. Use standard `Ticker` for `time` uniform incrementing.
   - Follow Flutter Impeller best practices for fragment shaders.

## Error Handling & Edge Cases
- **Shader Failure:** Fallback to a styled standard Flutter radial gradient (similar to current implementation) if the `FragmentProgram` fails to load.
- **Gesture Conflict:** Ensure the `onPanUpdate` of the orb doesn't conflict with any wrapping scroll views (though the world map is full-screen, so this shouldn't be an issue).

## Testing Strategy
- Unit test the routing logic and attribute data passing.
- Widget test the `CentralHealthOrb` to ensure tap counting works for the easter egg.
- Widget test `WorldTypeNode` to ensure colors and labels are correctly applied based on the `HabitAttribute`.
