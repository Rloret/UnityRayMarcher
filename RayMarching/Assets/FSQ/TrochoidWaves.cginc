
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
float _Steepness = 1;

float3 getWavePosition(in float3 gridPosition, int waveNumber);
float getAbsWavePosition(in float3 gridPosition, int waveNumber,float sign);
float getAbsWavePosition(in float3 gridPosition);

float3 computeDisplacementForPoint(float3 p) {
	float3 finalPosition = float3(0, 0, 0);
	for (int j = 0; j < _NumWaves; j++)
	{
		finalPosition += getWavePosition(p, j);
	}
	finalPosition /= _NumWaves;
	return finalPosition;
}
float hash(float2 p) {
	float h = dot(p, float2(127.1, 311.7));
	return frac(sin(h)*43758.5453123);
}
float noise(in float2 p) {
	float2 i = floor(p);
	float2 f = frac(p);
	float2 u = f * f*(3.0 - 2.0*f);
	return -1.0 + 2.0*lerp(
		lerp(hash(i + float2(0.0, 0.0)),
			hash(i + float2(1.0, 0.0)),
			u.x),
		lerp(hash(i + float2(0.0, 1.0)),
			hash(i + float2(1.0, 1.0)),
			u.x),
		u.y);
}
float F_z(float3 p) {
	float finalPosition = 0;
	float2x2 octave_m = float2x2(1.6, 1.2, -1.2, 1.6);
	float2  uv = p.xz;
	for (int j = 0; j < _NumWaves; j++)
	{
		uv =mul( octave_m,uv);
		finalPosition += getAbsWavePosition(float3(uv.x,p.y,uv.y), j,1);
		
	}
	finalPosition /= _NumWaves;
	return finalPosition;
}

float F0_z(float3 p,int numwaves) {
	wave w = waveBuffer[0];

	float finalPosition = 0;
	float h = 0;
	float k = PI2 / w.W;
	float a = w.H;
	float v = w.V;
	float3 uv = p.xxz;
	float2x2 octave_m = float2x2(1.6, 1.2, -1.2, 1.6);


	for (int j = 0; j < numwaves; j++)
	{
		
		finalPosition = getAbsWavePosition(k*(uv+_Time*v));
		finalPosition += getAbsWavePosition(k*(uv - _Time*v));
		h += finalPosition*a;
		k *= 1.4;
		a *= 0.22;
		v*=1.2;
	}
	finalPosition /= _NumWaves * 2;
	return h;
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

float getAbsWavePosition(in float3 gridPosition, int waveNumber,float s) {
	wave w = waveBuffer[waveNumber];
	
	float2 D = normalize(float2(cos(w.angle *PI / 180.0), sin(w.angle * PI / 180.0)));
	float k = PI2 / w.W;
	float3 distgridp = gridPosition + pow(w.H,2)*(sqrt(2)/2 -abs(noise(gridPosition.xz *k/10- _Time[2]*k)));

	float inTrig = dot(k*D, distgridp.xz) *k+ w.V *_Time*s;
	return w.H - abs(w.H*sin(inTrig));
	//return 10- abs(10*sin(gridPosition.x/10));
}

float getAbsWavePosition(in float3 gridPosition) {

	gridPosition += noise(gridPosition.xz);
	float2 D = normalize(float2(cos(gridPosition.x *PI / 180.0), sin(gridPosition.x * PI / 180.0)));
	float2 wv = 1.0 - abs(sin(gridPosition));
	float2 swv = abs(cos(gridPosition));
	wv = lerp(wv, swv, wv);
	return pow(1.0 - pow(wv.x * wv.y, 0.65), _Steepness);

}
