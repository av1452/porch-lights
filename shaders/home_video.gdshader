shader_type canvas_item;
// The 2003 touch: a warm, slightly faded grade, soft focus, film grain,
// a gentle vignette and a hint of camcorder color fringing at the edges.
// Toggle in Settings ("Home-video look").

uniform sampler2D screen: hint_screen_texture, filter_linear_mipmap;
uniform float grain = 0.035;
uniform float warmth = 0.06;
uniform float fade = 0.06;
uniform float softness = 0.0;
uniform float vignette = 0.35;
uniform float fringe = 0.0005;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 from_center = uv - 0.5;
	// color fringing grows toward the edges, like a cheap camcorder lens
	vec2 shift = from_center * fringe * 8.0;
	vec3 col;
	col.r = textureLod(screen, uv + shift, softness).r;
	col.g = textureLod(screen, uv, softness).g;
	col.b = textureLod(screen, uv - shift, softness).b;
	// warm it up and lift the blacks a little (faded print)
	col = col * (1.0 - fade) + fade * vec3(0.10, 0.08, 0.07);
	col.r += warmth * 0.6;
	col.g += warmth * 0.2;
	col.b -= warmth * 0.3;
	// gentle vignette
	float v = smoothstep(0.85, 0.25, length(from_center * vec2(1.25, 1.0)));
	col *= mix(1.0 - vignette, 1.0, v);
	// animated grain
	float n = hash(uv * vec2(1280.0, 720.0) + fract(TIME * 7.13) * 100.0) - 0.5;
	col += n * grain;
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
