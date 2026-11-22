// Cielo stilizzato di Animal World: gradiente morbido, disco del sole,
// disco della luna e stelle che compaiono di notte (GDD § 5.3).
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.43, 0.7, 0.94);
uniform vec3 horizon_color : source_color = vec3(0.81, 0.91, 0.98);
uniform vec3 ground_color : source_color = vec3(0.62, 0.79, 0.63);
uniform vec3 sun_direction = vec3(0.0, 1.0, 0.0);
uniform vec3 moon_direction = vec3(0.0, -1.0, 0.0);
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.8);
uniform float night = 0.0;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float up = dir.y;
	vec3 col = mix(horizon_color, top_color, smoothstep(0.0, 0.55, up));
	col = mix(col, ground_color, smoothstep(0.0, -0.25, up));
	// Alone caldo vicino al sole (alba e tramonto più belli).
	float sun_amount = max(dot(dir, normalize(sun_direction)), 0.0);
	col += sun_color * pow(sun_amount, 8.0) * 0.25;
	// Disco del sole
	col = mix(col, vec3(1.0, 0.98, 0.9), smoothstep(0.9985, 0.9992, sun_amount));
	// Luna
	float moon_amount = max(dot(dir, normalize(moon_direction)), 0.0);
	col = mix(col, vec3(0.95, 0.96, 1.0), smoothstep(0.9988, 0.9993, moon_amount) * night);
	// Stelle: punti fissi sulla volta, visibili solo di notte e sopra l'orizzonte.
	vec3 cell = floor(dir * 220.0);
	float star = step(0.9965, hash(cell));
	float twinkle = 0.7 + 0.3 * sin(TIME * 2.0 + hash(cell + 7.0) * 30.0);
	col += vec3(star * twinkle * night * smoothstep(0.02, 0.25, up));
	COLOR = col;
}
