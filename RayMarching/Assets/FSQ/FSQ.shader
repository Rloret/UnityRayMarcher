// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "RayMarching/FSQ" {
	
	Properties {

		_Sea_Base("Sea_Base", Color)= (0.1,0.19,0.22,1)
		_Sea_Water("Sea_Water", Color) = (0.8, 0.9, 0.6, 1)
	
		//_LazyRayMarch("use lazy marching", Float) = 0
		_Epsilon("MarchDistance", Range(0,1)) = 0.1
		_MaxMarchingSteps("Max marching steps", Range(0,255)) = 100
		
		_AuxValue("Aux",Range(1,10) )= 0
		_NoiseAmplitude("NoiseAmplitude",Range(1,100)) = 0

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

	
		#include "TrochoidWaves.cginc"
		#include "SDFUtility.cginc"

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
		uniform float4 _Sea_Base;
		uniform float4	_Sea_Water;
			
		fragOutput frag(fragInput IN) 
		{
			float3 D = normalize(getWorldUV(IN.UV.xy));
			Ray r = initRay(O, D);
			int steps = 0;



#if defined(LERP_RAYMARCH)
			float dist = marchSceneLerpSort(r, _MaxMarchingSteps, _Epsilon, steps);
#elif defined(BISECTION_RAYMARCH)
			float dist = marchSceneBisection(r, _MaxMarchingSteps, _Epsilon, steps);
#elif defined(SECANT_RAYMARCH)
			float dist = marchSceneSecant(r, _MaxMarchingSteps, _Epsilon, steps);
#else

		float dist = marchScene(r, _MaxMarchingSteps, _Epsilon, steps);

#endif 

	
		    clip(Far-dist-_Epsilon	);

			float3 p = getRayPoint(r, dist);

		
			fragOutput Out;

			
			//Out.col = float4(F_z(IN.UV.xyy) * float3(1, 1, 1).xyz, 1);
			//Out.col = float4(lambert*float3(1,1,1).xyz, 1);
		
#if  defined(NORMALS)
			float3 N = estimateNormal(p, _Epsilon);
			Out.col = float4(N, 1);
			
#elif defined(CONVERGENCE)
			float3 convergence = steps / _MaxMarchingSteps;
			Out.col = float4(convergence, 1);
#elif defined(DISTANCE)
			float3 d = (dist-Near)/(Far-Near);
			Out.col = float4(d, 1);
#else
		
			float3 L = _WorldSpaceLightPos0.xyz;
			float3 N = estimateNormal(p, _Epsilon);
			float lambert = pow(DotClamped(L, N) * 0.4 + 0.6, 80);
			float3 viewDir = normalize(_WorldSpaceCameraPos - p);
			float fresnel = clamp(1.0 - dot(N, viewDir), 0.0, 1.0);
			fresnel = pow(fresnel, 2.0);
			float3 reflectionDir = reflect(-L, N);
			float4 envSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, N);
			float3 specular = DecodeHDR(envSample, unity_SpecCube0_HDR).xyz;
			
			float3 refracted = _Sea_Base + lambert * _Sea_Water * 0.12;
			Out.col = float4(lerp(refracted, specular, fresnel),1);
			
		
#endif
			

			
			float4 projP = mul(UNITY_MATRIX_VP, float4(p.xyz, 1));
			float depth = projP.z / projP.w;

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

	CustomEditor "FullScreenQuadGUI"

}
