uniform sampler2D tDiffuse;
uniform float u_amount;
varying vec2 f_uv;

uniform float u_time;
uniform float u_size;
uniform vec2 u_resolution;
uniform float u_bpm;

float M_PI = 3.14159263;

// 2D Random
// https://thebookofshaders.com/11/
float random2 (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

/*
 * Generates pseudo-random noise from (x, y, z)
 * From http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
 */
float noise3(float x, float y, float z) {
	return fract(sin(dot(vec3(x, y, z) ,vec3(12.9898,78.233, 34.2838))) * 43758.5453);
}

/**
 * Cosine interpolates t between a and b
 * From the noise lecture (slide 26)
 */
float cosine_interp(float a, float b, float t) {
	float cos_t = (1.0 - cos(t * M_PI)) * 0.5;
	return a * (1.0 - cos_t) + b * cos_t;
}

/**
 * Interpolates the noise at (x, y, z) based on the 8 surrounding lattice
 * values (determined by the frequency)
 */
float interp_noise(float x, float y, float z, float freq) {
	float x0 = floor(x * freq),
		y0 = floor(y * freq),
		z0 = floor(z * freq),
	 	x1 = (x0 * freq + 1.0),
	 	y1 = (y0 * freq + 1.0),
	 	z1 = (z0 * freq + 1.0);

	float p1 = noise3(x0, y0, z0),
		p2 = noise3(x1, y0, z0),
		p3 = noise3(x0, y1, z0),
		p4 = noise3(x0, y0, z1),
		p5 = noise3(x0, y1, z1),
		p6 = noise3(x1, y1, z0),
		p7 = noise3(x1, y0, z1),
		p8 = noise3(x1, y1, z1);

	float dx = (x - x0) / (x1 - x0),
		dy = (y - y0) / (y1 - y0),
		dz = (z - z0) / (z1 - z0);

	// Interpolate along x
	float a1 = cosine_interp(p1, p2, dx),
		a2 = cosine_interp(p4, p7, dx),
		a3 = cosine_interp(p3, p6, dx),
		a4 = cosine_interp(p5, p8, dx);

	// Interpolate along y
	float b1 = cosine_interp(a1, a3, dy),
		b2 = cosine_interp(a2, a4, dy);

	// Interpolate along z
	float c = cosine_interp(b1, b2, dz);
	return c;
}


const float NUM_OCTAVES = 10.0;

/**
 * Sums NUM_OCTAVES octaves of increasingly smaller noise offsets
 * From the noise lecture (slide 29)
 */
float multi_octave_noise (float x, float y, float z) {
	float total = 0.0;
	float persistence = 0.8;

	for (float i = 0.0; i < NUM_OCTAVES; i += 1.0) {
		float freq = pow(2.0, 1.0);
		float amp = pow(persistence, 3.0);

		total += interp_noise(x, y, z, freq) * amp;
	}

	return total;
}

// 2D Noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise2 (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random2(i);
    float b = random2(i + vec2(1.0, 0.0));
    float c = random2(i + vec2(0.0, 1.0));
    float d = random2(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners porcentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}



void main() {
    vec4 col = texture2D(tDiffuse, f_uv);

		vec2 st = gl_FragCoord.xy / u_resolution.xy;

		vec2 position = vec2(st * cos(mod(u_time, u_bpm)));

		position.x = noise2(vec2(position.x + u_time, position.x + u_time));
		position.y = noise2(vec2(position.y + u_time, position.y + u_time));

		float radius = 1.0;
		float z = sqrt(radius * radius - position.x * position.x - position.y * position.y);
		vec3 normal = normalize(vec3(position.x, position.y, z));

		float t = 0.2 + (cos(u_time) / 4.0 + 0.5);
		col = col * (1.0 - t) + t * vec4(vec3(normal + 1.0)/2.0, 1.0);

		// --Default--
		float brightness = 1.4;
		float lightness = -0.3;

		col.r = col.r * brightness + lightness;
		col.g = col.g * brightness + lightness;
		col.b = col.b * brightness + lightness;

    gl_FragColor = col;

}
