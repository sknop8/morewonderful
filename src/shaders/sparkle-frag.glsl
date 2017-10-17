uniform sampler2D tDiffuse;
uniform float u_amount;
varying vec2 f_uv;

uniform float time;
uniform float size;

float M_PI = 3.14159263;

/*
 * Generates pseudo-random noise from (x, y, z)
 * From http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
 */
float noise_gen1(float x, float y, float z) {
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

	float p1 = noise_gen1(x0, y0, z0),
		p2 = noise_gen1(x1, y0, z0),
		p3 = noise_gen1(x0, y1, z0),
		p4 = noise_gen1(x0, y0, z1),
		p5 = noise_gen1(x0, y1, z1),
		p6 = noise_gen1(x1, y1, z0),
		p7 = noise_gen1(x1, y0, z1),
		p8 = noise_gen1(x1, y1, z1);

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


void main() {
    vec4 col = texture2D(tDiffuse, f_uv);

		float xRatio = 5.0;
		float yRatio = 3.0;
		float windowSize = 200.0;

		float sparkThres = size / 50.0;
		float n1 = floor(f_uv.x * xRatio * windowSize) / 5.0;
		float n2 = floor(f_uv.y * yRatio * windowSize) / 5.0;
		float n3 = floor(time * 10.0) / 10.0;
		float sparks = multi_octave_noise(n1, n2, n1 + n2);
		float t = noise_gen1(n1, n2, n3) * 0.5 + 0.5;
		//multi_octave_noise(f_uv.x * 100.0, f_uv.y * 100.0, f_uv.y * 100.0);
		if (sparks * t < sparkThres) {
			col += vec4(0.5);
		}

		// grain - https://www.reddit.com/r/opengl/comments/1rr4fy/any_good_ways_of_generating_film_grain_noise/
		float strength = 15.0;
		float x = (f_uv.x + 4.0) * (f_uv.y + 4.0) * (time * 10.0);
		vec3 grain = vec3(mod((mod(x, 13.0) + 1.0) * (mod(x, 123.0) + 1.0), 0.01) - 0.005);
		grain *= strength;

		col.r += grain.x;
		col.g += grain.y;
		col.b += grain.z;

		float brightness = 0.7;
		float lightness = 0.1;

		col.r = col.r * brightness + lightness;
		col.g = col.g * brightness + lightness;
		col.b = col.b * brightness + lightness;

    gl_FragColor = col;

}
