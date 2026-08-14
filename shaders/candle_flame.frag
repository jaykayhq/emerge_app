#include <flutter/runtime_effect.glsl>

// Uniforms are set by index from _CandleFlamePainter:
//   0-1: u_resolution (vec2)
//   2: u_time (float)
//   3: u_health (float, 0.0..1.0)
uniform vec2 u_resolution;
uniform float u_time;
uniform float u_health;

out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 34.5);
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
    float health = clamp(u_health, 0.0, 1.0);
    float aspect = u_resolution.x / u_resolution.y;
    float x = (uv.x - 0.5) * aspect;

    float base = 0.86;
    float height = mix(0.22, 0.62, health);
    float tip = base - height;
    float y = clamp((base - uv.y) / height, 0.0, 1.0);
    float sway = sin(u_time * 1.7) * 0.012 + sin(u_time * 3.1) * 0.006;
    float center = sway * (0.4 + y);
    float edgeNoise = (noise(vec2(uv.x * 11.0 + u_time * 0.25, uv.y * 8.0)) - 0.5) * 0.022;
    float width = mix(0.13, 0.18, health) * pow(max(0.0, 1.0 - y), 0.58) + 0.006;
    float edge = abs(x - center) - width - edgeNoise;
    float shape = 1.0 - smoothstep(0.0, 0.024, edge);
    float vertical = smoothstep(tip - 0.025, tip + 0.055, uv.y) *
        (1.0 - smoothstep(base - 0.02, base + 0.025, uv.y));
    shape *= vertical;

    float coreWidth = width * 0.46;
    float coreEdge = abs(x - center * 0.65) - coreWidth;
    float core = (1.0 - smoothstep(0.0, 0.018, coreEdge)) * vertical;
    core *= smoothstep(0.02, 0.42, y);

    vec3 outer = mix(vec3(1.0, 0.22, 0.025), vec3(1.0, 0.68, 0.08), health);
    vec3 gold = mix(outer, vec3(1.0, 0.93, 0.45), smoothstep(0.1, 0.8, y));
    vec3 color = mix(outer, gold, 0.7);
    color = mix(color, vec3(1.0, 0.98, 0.82), core);

    vec2 glowPoint = vec2(0.0, -0.10);
    float glowDistance = length(vec2(x, uv.y - 0.60) - glowPoint);
    float glow = exp(-glowDistance * 9.0) * (0.08 + health * 0.18);
    float alpha = clamp(max(shape * 0.92, glow), 0.0, 1.0);

    fragColor = vec4(color * alpha, alpha);
}
