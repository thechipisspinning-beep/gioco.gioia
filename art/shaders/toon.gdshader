// Shader toon morbido di Animal World (D-08).
// - Luce a due bande con transizione morbida (non "a scalini" duri).
// - Le ombre sono tinte di un colore freddo invece che semplicemente scurite:
//   è ciò che dà l'aspetto "illustrato" e accogliente.
// - Bordo luminoso (rim light) leggero sul lato illuminato.
// Funziona con tutti e tre i renderer (Forward+, Mobile, Compatibility).
shader_type spatial;
render_mode cull_back;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 shade_tint : source_color = vec4(0.62, 0.66, 0.92, 1.0);
uniform float shade_threshold : hint_range(-1.0, 1.0) = 0.05;
uniform float shade_softness : hint_range(0.0, 0.5) = 0.08;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.18;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
// Se attivo, il colore viene moltiplicato per il colore per-istanza/vertice
// (usato da MultiMesh per fiori ed erba: un solo materiale, tanti colori).
uniform bool use_vertex_color = false;

// I colori per vertice/istanza sono scritti in sRGB (come la palette) ma lo
// shader li riceve così come sono: vanno convertiti in lineare, altrimenti
// risultano più chiari e slavati.
// Il renderer Compatibility (web) li converte già da solo.
vec3 srgb_to_linear(vec3 c) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return c;
#else
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
#endif
}

void fragment() {
	ALBEDO = albedo.rgb * (use_vertex_color ? srgb_to_linear(COLOR.rgb) : vec3(1.0));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(shade_threshold - shade_softness, shade_threshold + shade_softness, ndl);
	band *= ATTENUATION;
	vec3 lit = mix(shade_tint.rgb * 0.55, vec3(1.0), band);
	DIFFUSE_LIGHT += lit * LIGHT_COLOR / PI;

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	SPECULAR_LIGHT += rim * rim_strength * band * LIGHT_COLOR / PI;
}
