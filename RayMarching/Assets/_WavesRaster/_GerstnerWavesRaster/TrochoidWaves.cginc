#include "Assets/_CGIncludes/NoiseUtility.cginc"
#define PI 3.141592653589793238462
#define PI2 6.283185307179586476924

struct wave {
	float H;
	float W;
	float V;
	float angle;
};


StructuredBuffer<wave> waveBuffer;

uniform int _NumWaves;
uniform float _NoiseAmplitude = 10.0;
uniform float _Angle;
uniform float _sAmplitude;
uniform float _cAmplitude;
//float3 getWavePosition(in float3 gridPosition, int waveNumber);
float getAbsWavePosition(float2 gridPosition, int waveNumber);
//float getAbsWavePosition(float2 gridPosition);






float F_z(float3 p) {
	float finalPosition = 0;
	
	float2  uv = p.xz;
	for (int j = 0; j < _NumWaves; j++)
	{
		finalPosition += getAbsWavePosition(uv, j);
		
	}
	finalPosition /= _NumWaves;

	return finalPosition;
}


float getAbsWavePosition(float2 gridPosition, int waveNumber) {
	wave w = waveBuffer[waveNumber];
	
	float2 D = normalize(float2(cos(w.angle *PI / 180.0), sin(w.angle * PI / 180.0)));
	float k = PI2 / w.W;
	float kNoise = PI2 / (w.W*_NoiseAmplitude);

	float inTrig = (dot(k*D, gridPosition) + PerlinNoise(gridPosition*kNoise)) *k+ w.V *_Time;
	return w.H - abs(w.H*(sin(inTrig)));

}


















/*

float noise(in float3 x)
{
float3 p = floor(x);
float3 f = smoothstep(0.0, 1.0, frac(x));
float n = p.x + p.y*57.0 + 113.0*p.z;

return lerp(lerp(lerp(hash(n + 0.0), hash(n + 1.0), f.x),
lerp(hash(n + 57.0), hash(n + 58.0), f.x), f.y),
lerp(lerp(hash(n + 113.0), hash(n + 114.0), f.x),
lerp(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
}

float3 computeDisplacementForPoint(float3 p) {
	float3 finalPosition = float3(0, 0, 0);
	for (int j = 0; j < _NumWaves; j++)
	{
		finalPosition += getWavePosition(p, j);
	}
	finalPosition /= _NumWaves;
	return finalPosition;
}
float hash(float n)
{
	return frac(cos(n)*41415.92653);
}


float getAbsWavePosition(float2 gridPosition) {

	gridPosition += float2(noise(gridPosition.xy),noise(gridPosition.yx));
	float2 D = normalize(float2(cos(gridPosition.x *PI / 180.0), sin(gridPosition.y * PI / 180.0)));
	float2 wv = 1.0 - abs(sin(gridPosition));
	float2 swv = abs(cos(gridPosition));
	wv = lerp(wv, swv, wv);
	return pow(1.0 - pow(wv.x * wv.y, 0.65), _Steepness);

}




float3 getWavePosition(in float3 gridPosition, int waveNumber) {

wave w = waveBuffer[waveNumber];
float k = PI2 / w.W;
float2 D = normalize(float2(cos(w.angle *PI / 180.0), sin(w.angle * PI / 180.0)));


float insideTrig = dot(k*D, gridPosition.xz) - k * w.V *_Time;

float3 wavePosition = float3(0, 0, 0);
wavePosition.xz = gridPosition.xz + _Steepness* (D / k)  * cos(insideTrig);
wavePosition.y = (w.H + w.H * sin(insideTrig)) / 2.0;

return wavePosition;

}



float3x3 m = float3x3(0.00, 1.60, 1.20, -1.60, 0.72, -0.96, -1.20, -0.96, 1.28);

 Fractional Brownian motion
float fbm(float3 p)
{
float f = 0.5000*noise(p); p = mul(m,p*1.1);
f += 0.2500*noise(p); p = mul(m,p*1.2);
f += 0.1666*noise(p); p = mul(m,p);
f += 0.0834*noise(p);
return f;
}

float2x2 m2 = float2x2(1.6, -1.2, 1.2, 1.6);

 Fractional Brownian motion
float fbm(float2 p)
{
float f = 0.5000*noise(p); p = mul(m2,p);
f += 0.2500*noise(p); p = mul(m2,p);
f += 0.1666*noise(p); p = mul(m2,p);
f += 0.0834*noise(p);
return f;
}



float F0_z(float3 p,int numwaves) {
	wave w = waveBuffer[0];

	float finalPosition = 0;
	float h = 0;
	float k = PI2 / w.W;
	float a = w.H;
	float v = w.V;
	float2 uv = p.xz;
	float2x2 octave_m = float2x2(1.6, 1.2, -1.2, 1.6);


	for (int j = 0; j < numwaves; j++)
	{
		uv += mul(octave_m, uv);
		finalPosition = getAbsWavePosition(k*(uv - _Time[2] * v));
		finalPosition += getAbsWavePosition(k*(uv - _Time[2]*v));
		h += finalPosition*a;
		k *= 1.9;
		a *= 0.9;
		v*=1.2;
	}
	h /= _NumWaves*2 ;
	return h;
}

*/
