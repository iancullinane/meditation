// Rain and Snow shader by Brian Smith (steampunkdemon.itch.io)
// MIT licence

shader_type canvas_item;

uniform float rain_amount : hint_range(50.0, 2000.0) = 500.0;
uniform float near_rain_length : hint_range(0.01, 0.5) = 0.12;
uniform float far_rain_length : hint_range(0.01, 0.5) = 0.06;
uniform float near_rain_width : hint_range(0.1, 3.0) = 1.2;
uniform float far_rain_width : hint_range(0.1, 3.0) = 0.8;
uniform float near_rain_transparency : hint_range(0.1, 1.0) = 1.0;
uniform float far_rain_transparency : hint_range(0.1, 1.0) = 0.7;
// Replace the below reference to source_color with hint_color if you are using a version of Godot before 4.
uniform vec4 rain_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float base_rain_speed : hint_range(0.1, 1.0) = 0.5;
uniform float additional_rain_speed : hint_range(0.1, 1.0) = 0.5;
uniform float slant : hint_range(-1.0, 1.0) = 0.2;

// Ripple effect parameters
uniform float ripple_scale : hint_range(4.0, 264.0) = 32.0;
uniform float ripple_brightness : hint_range(0.0, 1.0) = 0.2;
uniform float ripple_speed : hint_range(0.1, 2.0) = 0.5;
uniform float ripple_density_multiplier : hint_range(0.0, 2.0) = 1.0;
uniform float ripple_spawn_chance_min : hint_range(0.0, 1.0) = 0.15;
uniform float ripple_spawn_chance_max : hint_range(0.0, 1.0) = 0.7;

// Hash function for random ripple positions
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
// To control the rainfall from your program comment out the below line and add a new uniform above as:
// uniform float time = 10000.0;
// Then update the time uniform from your _physics_process function by adding delta. You can then pause the rainfall by not changing the time uniform.
	float time = 10000.0 + TIME;

// Uncomment the following line if you are applying the shader to a TextureRect and using a version of Godot before 4.
//	COLOR = texture(TEXTURE,UV);

	vec2 uv = vec2(0.0);
	float remainder = mod(UV.x - UV.y * slant, 1.0 / rain_amount);
	uv.x = (UV.x - UV.y * slant) - remainder;
	float rn = fract(sin(uv.x * rain_amount));
	uv.y = fract((UV.y + rn));

// Blurred trail. Works well for rain:
//	COLOR = mix(COLOR, rain_color, smoothstep(1.0 - (far_rain_length + (near_rain_length - far_rain_length) * rn), 1.0, fract(uv.y - time * (base_rain_speed + additional_rain_speed * rn))) * (far_rain_transparency + (near_rain_transparency - far_rain_transparency) * rn) * step(remainder * rain_amount, far_rain_width + (near_rain_width - far_rain_width) * rn));

// No trail. Works well for snow:
	COLOR = mix(COLOR, rain_color, step(1.0 - (far_rain_length + (near_rain_length - far_rain_length) * rn), fract(uv.y - time * (base_rain_speed + additional_rain_speed * rn))) * (far_rain_transparency + (near_rain_transparency - far_rain_transparency) * rn) * step(remainder * rain_amount, far_rain_width + (near_rain_width - far_rain_width) * rn));

	// Add ripple effect - density scales with rain amount
	// Normalize rain_amount (50-2000) to a 0-1 factor
	float rain_factor = clamp((rain_amount - 50.0) / 1950.0, 0.0, 1.0);
	float ripple_density = rain_factor * ripple_density_multiplier;
	
	vec2 ripple_uv = UV * ripple_scale;
	vec2 grid_pos = floor(ripple_uv);
	float ripple_intensity = 0.0;
	
	// Check nearby grid cells for ripples
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 cell = grid_pos + vec2(float(x), float(y));
			
			// Random offset within cell
			float rand_x = hash(cell);
			float rand_y = hash(cell + vec2(13.37, 42.42));
			vec2 ripple_center = cell + vec2(rand_x, rand_y);
			
			// Stagger ripple timing - faster with more rain
			float time_offset = hash(cell + vec2(99.99, 11.11));
			float t = fract(time_offset + TIME * ripple_speed * (1.0 + ripple_density * 0.5));
			
			// Distance from ripple center
			float dist = length(ripple_uv - ripple_center);
			
			// Expanding ring
			float ring_radius = t * 2.0;
			float ring_thickness = 0.2;
			float ring = abs(dist - ring_radius);
			
			// Spawn chance increases with rain intensity
			// At low rain (50), uses min spawn %, at high rain (2000), uses max spawn %
			float spawn_probability = mix(ripple_spawn_chance_min, ripple_spawn_chance_max, ripple_density);
			float spawn_chance = step(1.0 - spawn_probability, rand_x);
			
			// Ring intensity that fades over time
			float ring_alpha = smoothstep(ring_thickness, 0.0, ring) * (1.0 - t) * spawn_chance;
			ripple_intensity += ring_alpha;
		}
	}
	
	// Apply ripple as brightness boost
	ripple_intensity = clamp(ripple_intensity, 0.0, 1.0);
	COLOR.rgb += vec3(ripple_brightness * ripple_intensity);
}