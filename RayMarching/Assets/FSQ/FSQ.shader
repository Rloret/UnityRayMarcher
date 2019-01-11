// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "RayMarching/FSQ" {
	Properties {

		_Epsilon("MarchDistance", Range(0,1)) = 0.1
		_MaxMarchingSteps("Max marching steps", Range(0,255)) = 100
		
		_AuxValue("Aux",Float) = 0

	}
	SubShader{

		Blend SrcAlpha OneMinusSrcAlpha

		Pass{
		CGPROGRAM
		//ATENTION: note that Unity follows camera pointing to positive.
		//however, in the basis vectors z is pointing to the negative as in opengl convenction
		#define F UNITY_MATRIX_V[2].xyz
		#define R UNITY_MATRIX_V[0].xyz
		#define U UNITY_MATRIX_V[1].xyz
		#define Near _ProjectionParams.y
		#define Far  _ProjectionParams.z
		#define O _WorldSpaceCameraPos.xyz

		#include "UnityShaderVariables.cginc"
		#include "TrochoidWaves.cginc"
		#include "SDFUtility.cginc"

		#pragma vertex vert
		#pragma fragment frag
		#pragma target 5.0




		struct vertInput
		{
			float4 pos: POSITION;
			float2 UV:  TEXCOORD0;
			
		};

		struct fragInput
		{
			float4 pos: SV_POSITION;
			float2 UV:  TEXCOORD0;
			
		};

		struct fragOutput
		{
			float4 col: COLOR;
			float depth:  DEPTH;

		};

		fragInput vert(vertInput IN)
		{
			fragInput OUT;
			OUT.pos = IN.pos;
			OUT.pos.xy *= 2;
			OUT.pos.z = 1;
			
			OUT.UV = IN.UV;
			return OUT;
		}
		
		uniform half _MaxMarchingSteps;
		uniform float _Epsilon;


		fragOutput frag(fragInput IN) 
		{
			float3 D = normalize(getWorldUV(IN.UV.xy));
			Ray r = initRay(O, D);
			int steps = 0;
			float dist = marchScene(r, _MaxMarchingSteps, _Epsilon,  steps);
		    clip(Far-dist-_Epsilon	);

			float3 p = getRayPoint(r, dist);
			float3 L = _WorldSpaceLightPos0.xyz;
			float3 N = estimateNormal(p, _Epsilon);
			float lambert = dot(L, N);

			float4 projP = mul(UNITY_MATRIX_VP, float4(p.xyz,1));
			float depth =  projP.z / projP.w;
			fragOutput Out;

			
			//Out.col = float4(F_z(IN.UV.xyy) * float3(1, 1, 1).xyz, 1);
			//Out.col = float4(lambert*float3(1,1,1).xyz, 1);
			float3 convergence = steps / _MaxMarchingSteps;
			Out.col = float4(convergence, 1);

			


#if defined(UNITY_REVERSED_Z)
			Out.depth = depth;
#else
			Out.depth = 1-depth	;
#endif
			return Out;
		
		}

		
		ENDCG

		}
	}

}
