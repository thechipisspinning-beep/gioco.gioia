// Acqua stilizzata: colore che va dall'azzurro chiaro al blu, increspature
// leggere animate e riflessi a bande. Compatibile con tutti i renderer.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec4 shallow_color : source_color = vec4(0.52, 0.83, 0.93, 1.0);
uniform vec4 deep_color : source_color = vec4(0.26, 0.6, 0.83, 1.0);
uniform float wave_scale = 0.08;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float w = sin(p.x * wave_scale + TIME * 0.8) * 0.5 + sin(p.y * wave_scale * 1.3 - TIME * 0.6) * 0.5;
	float sparkle = smoothstep(0.85, 0.95, sin(p.x * 0.6 + TIME) * sin(p.y * 0.5 - TIME * 0.7));
	vec3 col = mix(deep_color.rgb, shallow_color.rgb, 0.5 + 0.25 * w);
	ALBEDO = col + vec3(sparkle * 0.25);
	ROUGHNESS = 1.0;
	NORMAL = normalize(NORMAL + vec3(w * 0.04, 0.0, w * 0.03));
}
