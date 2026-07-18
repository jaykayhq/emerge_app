// shaders/cracked_orb.frag
#include <flutter/runtime_effect.glsl>

// Uniforms are set by index from the Dart painter:
//   0: u_resolution (vec2)
//   1: u_time (float)
//   2: u_pan (vec2)
//   3: u_health_pct (float, 0.0..1.0)
uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_pan;
uniform float u_health_pct;

out vec4 fragColor;

// Cheap hash-based value noise for surface "continents" / banding.
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / u_resolution;
    vec2 p = uv - vec2(0.5);
    p.x *= u_resolution.x / u_resolution.y; // keep the disc circular
    float r = length(p);

    // Transparent outside the planet disc.
    if (r > 0.5) {
        fragColor = vec4(0.0);
        return;
    }

    // 3D normal of the sphere surface.
    vec3 n = vec3(p * 2.0, sqrt(max(0.0, 1.0 - r * r * 4.0)));

    // Slow auto-rotation + interactive drag offset.
    float rot = u_time * 0.15 + u_pan.x * 0.6;
    mat2 spin = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    vec3 ns = vec3(spin * n.xy, n.z);

    // Light direction orbiting over time.
    vec3 lightDir = normalize(vec3(sin(u_time * 0.3), 0.35, cos(u_time * 0.3)));
    float diffuse = clamp(dot(ns, lightDir), 0.0, 1.0);

    // Surface detail: rotating lat/long bands + soft continents.
    float bands = noise(ns.xy * 3.0 + vec2(rot * 2.0, 0.0));
    float continents = noise(ns.xy * 5.0 + ns.z * 2.0 + rot);
    float surface = mix(0.85, 1.12, bands * 0.5 + continents * 0.5);

    // Health-driven palette: healthy = teal/blue planet,
    // unhealthy = warm red. No flat black cracks.
    vec3 healthy = mix(vec3(0.04, 0.45, 0.55), vec3(0.17, 0.93, 0.47), 0.6);
    vec3 sick = vec3(0.75, 0.18, 0.15);
    vec3 base = mix(sick, healthy, clamp(u_health_pct, 0.0, 1.0));
    base *= surface;

    // Diffuse shading with a soft ambient floor so the dark side isn't black.
    float shade = 0.25 + 0.95 * diffuse;
    vec3 color = base * shade;

    // Limb darkening (subtle) + atmosphere rim glow.
    float limb = smoothstep(0.5, 0.42, r);
    color *= mix(0.75, 1.0, limb);
    float rim = smoothstep(0.46, 0.5, r) * (1.0 - smoothstep(0.5, 0.52, r));
    color += mix(sick, healthy, u_health_pct) * rim * 0.6;

    fragColor = vec4(color, 1.0);
}
