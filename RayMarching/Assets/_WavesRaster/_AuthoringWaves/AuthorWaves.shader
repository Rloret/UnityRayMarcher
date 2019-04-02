Shader "Waves/AuthorWaves"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
			#pragma target 5.0

            #include "UnityCG.cginc"
			#include "Assets/_WavesRaster/_GerstnerWavesRaster/TrochoidWaves.cginc"


		   struct vertInput
		{
			half4 pos: POSITION;
			half2 UV:  TEXCOORD0;

		};

		struct fragInput
		{
			half4 pos: SV_POSITION;
			half2 UV:  TEXCOORD0;
			half4 wpos :TEXCOORD1;
			half3 normal: TEXCOORD2;


		};

		struct fragOutput
		{
			half4 col: COLOR;
			half depth:  DEPTH;

		};

		float3 computeNormal(float3 Position) {

			float3 offset = float3(1., 0., -1.) *0.001; //*geom_normalStep.xyy ;


			float3 center = float3(Position.x,F_z(Position)				,Position.z);
			float3 top =    float3(Position.x,F_z(Position + offset.yyx),Position.z);
			float3 bottom = float3(Position.x,F_z(Position + offset.yyz),Position.z);
			float3 right =  float3(Position.x,F_z(Position + offset.xyy),Position.z);
			float3 left =   float3(Position.x,F_z(Position + offset.zyy),Position.z);

			float3 na = cross(top - center, right - center);
			float3 nb = cross(left - center, top - center);
			float3 nc = cross(bottom - center, left - center);
			float3 nd = cross(right - center, bottom - center);

			float3 bump = normalize(na + nb + nc + nd);

			return bump;
		}


		fragInput vert(vertInput IN)
		{
			fragInput OUT;
			OUT.pos = IN.pos;
			OUT.pos = mul(unity_ObjectToWorld, OUT.pos);
			
			OUT.pos.y += F_z(OUT.pos);
			OUT.wpos = OUT.pos;
			//OUT.normal = computeNormal(OUT.pos);

			OUT.pos = mul(UNITY_MATRIX_VP, OUT.pos);
			OUT.UV = IN.UV;
			return OUT;
		}
		
		float4 frag(fragInput IN) :SV_TARGET
		{
			float3 Position = IN.wpos;
			float3 offset = float3(1., 0., -1.); //*geom_normalStep.xyy ;


			float3 center = Position;
			float3 top = Position;
			//top.y =Position.y+ F_z(Position);
			float3 bottom = float3(Position.x,F_z(Position + offset.yyz),Position.z);
			float3 right =  float3(Position.x,F_z(Position + offset.xyy),Position.z);
			float3 left =   float3(Position.x,F_z(Position + offset.zyy),Position.z);

			float3 na = cross((top - center), (right - center));
			float3 nb = cross(left - center, top - center);
			float3 nc = cross(bottom - center, left - center);
			float3 nd = cross(right - center, bottom - center);

			float3 bump = normalize(na + nb + nc + nd);


			return float4(Position,1);
			
		}
            ENDCG
        }
    }

}
