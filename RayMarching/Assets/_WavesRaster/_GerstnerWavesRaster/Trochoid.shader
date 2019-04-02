

Shader "ShaderDev/Trochoid" {

	Properties{

	}

	Subshader{
		Tags{
		"LightMode" = "ForwardBase"
	}
		Pass{
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 5.0

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

	struct vertexInput {
		float4 P: POSITION;
		float4 N: NORMAL;

	};

	struct fragmentInput {
		float4 v_P: TEXCOORD0;
		float4 P  :SV_POSITION;
	};

	float3 computeDisplacementForPoint(float3 p) {
		float3 finalPosition = float3(0, 0, 0);
		for (int j = 0; j < _NumWaves; j++)
		{
			finalPosition += getWavePosition(p, j);
		}
		finalPosition /= _NumWaves;
		return finalPosition;
	}


	fragmentInput vert(vertexInput i) {
		fragmentInput o;
		float3 finalPosition = computeDisplacementForPoint(i.P);
		/*float3(0, 0, 0);
		for (int j = 0; j < _NumWaves; j++)
		{
			finalPosition += getWavePosition(i.P, j);
		}
		finalPosition /= _NumWaves;*/

		o.P = UnityObjectToClipPos(finalPosition);
		return o;
	}


	float3 getWavePosition(in float3 gridPosition, int waveNumber) {
		wave w = waveBuffer[waveNumber];
		float k = PI2 / w.W;
		float2 D = normalize(float2(cos(w.angle *PI / 180.0), sin(w.angle * PI / 180.0)));
		

		float insideTrig = dot(k*D, gridPosition.xz) - k * w.V *_Time;

		float3 wavePosition = float3(0, 0, 0);
		wavePosition.xz = gridPosition.xz + _Steepness * (D / k)  * cos(insideTrig);
		wavePosition.y = (w.H + w.H * sin(insideTrig)) / 2.0;

		return wavePosition;

	}

	half4 frag(fragmentInput i) :COLOR{
		wave w = waveBuffer[0];

		float2 D = float2(cos(w.angle *PI / 180.0), sin(w.angle * PI / 180.0));
		half4 c = half4(D.x, D.y, 0, 1);
		return c;
	}
		ENDCG
	}
	}
}
