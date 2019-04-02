
Shader "Waves/RayMarching/FSQ_Marching_Test" {
	
	Properties{

		_Epsilon("MarchDistance", Range(0,1)) = 0.1
		_MaxMarchingSteps("Max marching steps", Range(0,255)) = 100



	}
		SubShader{
		Tags{ "Queue" = "Transparent" }
			Blend SrcAlpha OneMinusSrcAlpha

			Pass{
			CGPROGRAM

			#define F UNITY_MATRIX_V[2].xyz
			#define R UNITY_MATRIX_V[0].xyz
			#define U UNITY_MATRIX_V[1].xyz
			#define Near _ProjectionParams.y
			#define Far  _ProjectionParams.z
			#define O _WorldSpaceCameraPos.xyz

			half mapScene(half3 p);



		#include "Assets/_CGIncludes/TrochoidWaves.cginc"

		#include "Assets/_CGIncludes/SDFUtility.cginc"

		#include "UnityStandardBRDF.cginc"


		#pragma vertex vert
		#pragma fragment frag
		#pragma target 5.0
	
		#pragma shader_feature LERP_RAYMARCH
		#pragma shader_feature BISECTION_RAYMARCH
		#pragma shader_feature SECANT_RAYMARCH

		#pragma shader_feature NORMALS
		#pragma shader_feature DISTANCE
	    #pragma shader_feature CONVERGENCE
		#pragma shader_feature LIGHTING
		#pragma shader_feature ALL



		struct vertInput
		{
			half4 pos: POSITION;
			half2 UV:  TEXCOORD0;
			
		};

		struct fragInput
		{
			half4 pos: SV_POSITION;
			half2 UV:  TEXCOORD0;
			half3 D: TEXCOORD1;
			
		};

		struct fragOutput
		{
			half4 col: COLOR;
			half depth:  DEPTH;

		};

		fragInput vert(vertInput IN)
		{
			fragInput OUT;
			OUT.pos = IN.pos;
			OUT.pos.xy *= 2;
			OUT.pos.z = 1;
			OUT.D = getWorldUV(IN.UV.xy);
			OUT.UV = IN.UV;
			return OUT;
		}

		uniform half _MaxMarchingSteps;

		uniform half _Epsilon;

	

		half mapScene(half3 p) {

			half sDist = sdSphere(p + half3(0, 0, 1),20);
			return sDist;
		}
		
		

		fragOutput frag(fragInput IN)
		{
			half3 D = normalize(IN.D);//getWorldUV(IN.UV.xy));
			Ray r = initRay(O, D);
			int steps = 0;

			fragOutput Out;

			float dist = marchScene(r, _MaxMarchingSteps, _Epsilon, steps);

			clip(Far - dist - _Epsilon);

			half3 p = getRayPoint(r, dist);
			float3 N = estimateNormal(p, _Epsilon);
	    
			half4 projP = mul(UNITY_MATRIX_VP, half4(p.xyz, 1));
			half depth = projP.z / projP.w;
		
			Out.col.rgb = N;
			Out.col.a = 1;

			Out.depth = depth;
#ifndef UNITY_REVERSED_Z
			Out.depth =1- depth;
#endif
			return Out;
		
		}
				
		ENDCG

		}
	}



}
