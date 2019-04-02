//	Simplex 3D Noise 
//	by Ian McEwan, Ashima Arts
//
half4 permute(half4 x) { return fmod(((x*34.0) + 1.0)*x, 289.0); }
half4 taylorInvSqrt(half4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

half hash(half n) { return frac(sin(n) * 1e4); }
half hash(half2 p) { return frac(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }
half3 hash(half3 x)
{
	x = half3(dot(x, half3(127.1, 311.7, 74.7)),
		dot(x, half3(269.5, 183.3, 246.1)),
		dot(x, half3(113.5, 271.9, 124.6)));

	return frac(sin(x)*43758.5453123);
}
half noise(half x) {
	half i = floor(x);
	half f = frac(x);
	half u = f * f * (3.0 - 2.0 * f);
	return lerp(hash(i), hash(i + 1.0), u);
}

half3 hash33w(half3 p3)
{
	p3 = frac(p3 * half3(0.1031f, 0.1030f, 0.0973f));
	p3 += dot(p3, p3.yxz + 19.19f);
	return frac((p3.xxy + p3.yxx)*p3.zyx);

}

half3 hash33s(half3 p3)
{
	p3 = frac(p3 * half3(0.1031f, 0.11369f, 0.13787f));
	p3 += dot(p3, p3.yxz + 19.19f);
	return -1.0f + 2.0f * frac(half3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

half noise(half2 x) {
	half2 i = floor(x);
	half2 f = frac(x);

	// Four corners in 2D of a tile
	half a = hash(i);
	half b = hash(i + half2(1.0, 0.0));
	half c = hash(i + half2(0.0, 1.0));
	half d = hash(i + half2(1.0, 1.0));

	// Simple 2D lerp using smoothstep envelope between the values.
	// return half3(lerp(lerp(a, b, smoothstep(0.0, 1.0, f.x)),
	//			lerp(c, d, smoothstep(0.0, 1.0, f.x)),
	//			smoothstep(0.0, 1.0, f.y)));

	// Same code, with the clamps in smoothstep and common subexpressions
	// optimized away.
	half2 u = f * f * (3.0 - 2.0 * f);
	return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// This one has non-ideal tiling properties that I'm still tuning
half noise(half3 x) {
	const half3 step = half3(110, 241, 171);

	half3 i = floor(x);
	half3 f = frac(x);

	// For performance, compute the base input to a 1D hash from the integer part of the argument and the 
	// incremental change to the 1D based on the 3D -> 1D wrapping
	half n = dot(i, step);

	half3 u = f * f * (3.0 - 2.0 * f);
	return lerp(lerp(lerp(hash(n + dot(step, half3(0, 0, 0))), hash(n + dot(step, half3(1, 0, 0))), u.x),
		lerp(hash(n + dot(step, half3(0, 1, 0))), hash(n + dot(step, half3(1, 1, 0))), u.x), u.y),
		lerp(lerp(hash(n + dot(step, half3(0, 0, 1))), hash(n + dot(step, half3(1, 0, 1))), u.x),
			lerp(hash(n + dot(step, half3(0, 1, 1))), hash(n + dot(step, half3(1, 1, 1))), u.x), u.y), u.z);
}

half PerlinNoise(in half2 p) {
	half2 i = floor(p);
	half2 f = frac(p);
	half2 u = smoothstep(half2(0, 0), half2(1, 1), f);
	return -1.0 + 2.0*lerp(
		lerp(hash(i + half2(0.0, 0.0)),
			hash(i + half2(1.0, 0.0)),
			u.x),
		lerp(hash(i + half2(0.0, 1.0)),
			hash(i + half2(1.0, 1.0)),
			u.x),
		u.y);
}



half3 voronoi(in half3 x)
{
	half3 p = floor(x);
	half3 f = frac(x);

	half id = 0.0;
	half2 res = half2(100.0, 100.0);
	for (int k = -1; k <= 1; k++)
		for (int j = -1; j <= 1; j++)
			for (int i = -1; i <= 1; i++)
			{
				half3 b = half3(half(i), half(j), half(k));
				half3 r = half3(b)-f + hash(p + b);
				half d = dot(r, r);

				if (d < res.x)
				{
					id = dot(p + b, half3(1.0, 57.0, 113.0));
					res = half2(d, res.x);
				}
				else if (d < res.y)
				{
					res.y = d;
				}
			}

	return half3(sqrt(res), abs(id));
}

//------------------------------------------------------------------------------------------
// Simplex Noise
//------------------------------------------------------------------------------------------

half simplex(half3 pos)
{


	const half K1 = 0.333333333;
	const half K2 = 0.166666667;

	half3 i = floor(pos + (pos.x + pos.y + pos.z) * K1);
	half3 d0 = pos - (i - (i.x + i.y + i.z) * K2);

	half3 e = step(half3(0,0,0), d0 - d0.yzx);
	half3 i1 = e * (1.0 - e.zxy);
	half3 i2 = 1.0 - e.zxy * (1.0 - e);

	half3 d1 = d0 - (i1 - 1.0 * K2);
	half3 d2 = d0 - (i2 - 2.0 * K2);
	half3 d3 = d0 - (1.0 - 3.0 * K2);

	half4 h = max(0.6 - half4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
	half4 n = h * h * h * h * half4(dot(d0, hash33s(i)), dot(d1, hash33s(i + i1)), dot(d2, hash33s(i + i2)), dot(d3, hash33s(i + 1.0)));

	return dot(half4(1,1,1,1)*31.316, n);
}

half getSimplexFbm(half3 pos, half octaves, half persistence, half scale)
{
	half final = 0.0;
	half amplitude = 1.0;
	half maxAmplitude = 0.0;

	for (half i = 0.0; i < octaves; ++i)
	{
		half s = simplex(pos * scale);
		s = s * 2 - 1;
		final += s * amplitude;
		scale *= 2.0;
		maxAmplitude += amplitude;
		amplitude *= persistence;
	}
	final /= maxAmplitude;
	//final = (min(final, 1.0f) + 1.0f) * 0.5f;
	return final;
}

half worley(in half3 x)
{
	half3 p = floor(x);
	half3 f = frac(x);

	half result = 1.0f;

	for (int k = -1; k <= 1; ++k)
	{
		for (int j = -1; j <= 1; ++j)
		{
			for (int i = -1; i <= 1; ++i)
			{
				half3 b = half3(half(i), half(j), half(k));
				half3 r = b - f + hash33w(p + b);
				half d = dot(r, r);

				result = min(d, result);
			}
		}
	}

	return sqrt(result);
}

half4 fade(half4 t)
{
	return (t * t * t) * (t * (t * half4(6,6,6,6) - half4(15,15,15,15)) + half4(10,10,10,10));
}

half remap(half originalValue, half originalMin, half originalMax, half newMin, half newMax)
{
	return newMin + (((originalValue - originalMin) / (originalMax - originalMin)) * (newMax - newMin));
}


half getValueNoiseFBM(half3 p, half f, int octaves) {
	
	half fbm = 0;
	half sum = 0;
	half lacunarity = 2;
	for (int i = 0; i < octaves; i++)
	{
		fbm = noise(p/f);
		sum += fbm;
		f *= lacunarity;
	}
	sum /= octaves;
	sum = saturate(sum);
	return sum;

}

half getVoroNoiseFBM(half3 pos, int octaves, float persistence, float scale)
{
	half final = 0.0;
	half amplitude = 1.0;
	half maxAmplitude = 0.0;

	for (half i = 0.0; i < octaves; ++i)
	{
		final += worley(pos * scale)* amplitude;
		scale *= persistence;
		maxAmplitude += amplitude;
		amplitude *= persistence;
	}
	//final /= maxAmplitude;
	final =saturate(final);
	return final;
}


float cells(float3 p, float cellCount)
{
	float3 pCell = p * cellCount;
	float d = 1.0e10;
	for (int xo = -1; xo <= 1; xo++)
	{
		for (int yo = -1; yo <= 1; yo++)
		{
			for (int zo = -1; zo <= 1; zo++)
			{
				float3 tp = floor(pCell) + float3(xo, yo, zo);

				tp = pCell - tp - noise(fmod(tp, cellCount / 1.0));

				d = min(d, dot(tp, tp));
			}
		}
	}
	d = min(d, 1.0);
	d = max(d, 0.0f);

	return d;
}

float tileableworley(float3 p, float cellCount)
{
	return cells(p, cellCount);
}




