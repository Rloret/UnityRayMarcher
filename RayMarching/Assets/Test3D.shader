// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Test3D"
{
	Properties{
		_Volume("Texture", 3D) = "" {}
	}
		SubShader{
		Pass{

		CGPROGRAM
#pragma vertex vert
#pragma fragment frag


#include "UnityCG.cginc"

		struct vs_input {
		float4 vertex : POSITION;
	};

	struct ps_input {
		float4 pos : SV_POSITION;
		float3 wpos : TEXCOORD1;
		float3 uv : TEXCOORD0;
	};


	ps_input vert(vs_input v)
	{
		ps_input o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.wpos = mul(unity_ObjectToWorld, v.vertex);
		o.uv = v.vertex.xyz;
		return o;
	}

	sampler3D _Volume;

	float4 frag(ps_input i) : COLOR
	{
		return tex3D(_Volume, ((i.wpos / 256.0)+0.5)/2 );//(i.uv+0.5)/2);
	}

		ENDCG

	}
	}

		Fallback "VertexLit"
}
