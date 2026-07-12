// shaders/cracked_orb.frag
#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_pan;
uniform float u_health_pct; // 0.0 to 1.0

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / u_resolution;
    // Simple placeholder logic for an orb with cracks and rotation
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    
    if (dist > 0.5) {
        fragColor = vec4(0.0);
        return;
    }
    
    // Simulate 3D rotation with pan
    vec2 rotatedUv = uv + u_pan * 0.1;
    
    // Simulated cracks based on health (lower health = more visible)
    float crack = sin(rotatedUv.x * 20.0 + u_time) * cos(rotatedUv.y * 20.0 + u_time);
    float crackIntensity = (1.0 - u_health_pct) * step(0.8, crack);
    
    // Base glow
    vec3 baseColor = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), u_health_pct);
    vec3 finalColor = mix(baseColor, vec3(0.0), crackIntensity);
    
    // 3D Sphere shading
    float lighting = 1.0 - (dist / 0.5);
    finalColor *= lighting;
    
    fragColor = vec4(finalColor, 1.0);
}
