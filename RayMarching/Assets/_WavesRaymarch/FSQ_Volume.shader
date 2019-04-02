
Shader "volume/RayMarching/FSQ_Volume" {
	
	Properties{

		//_Sea_Base("Sea_Base", Color) = (0.1,0.19,0.22,1)
		//_Sea_Water("Sea_Water", Color) = (0.8, 0.9, 0.6, 1)

		//_LazyRayMarch("use lazy marching", half) = 0

		_CloudNoise("CloudNoise", 3D) = "black"{}

		_Epsilon("MarchDistance", Range(0,1)) = 0.1
		_MaxMarchingSteps("Max marching steps", Range(0,255)) = 100

		_FValue("F",Range(0,1000)) = 0
		_WLac("Worley Lacunarity",Range(0,2.0)) = 0.5
		_SLac("Simplex Lacunarity",Range(0.0,2.0)) = 0.5
		_Mix("mu",Range(0.9,1.0)) = 0.5

		_Aux("Aux",Range(0.0,20.0)) = 1

	}
		SubShader{
		Tags{ "Queue" = "Transparent" }
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
		sampler3D _CloudNoise;
		uniform half _MaxMarchingSteps;
		uniform half _Aux;
		uniform half _Epsilon;
		uniform half _FValue;
		uniform half _WLac;
		uniform half _SLac;
		uniform half _Mix;
		uniform half4 _Sea_Base;
		uniform half4	_Sea_Water;

		static const half3 scattering =200* half3(0.1, 0.1, .1);
		static const half3 absorption = 0* half3(0.1, 0.1, 0.1);

#define extintion (scattering + absorption)

		half getDensity(half3 p) {

			half density = tex3Dlod(_CloudNoise, float4(p / 20,0));
			return density;
		}
			

		half3 getShadowVolumeTransmitance(half shadowStep, half3 p, half3 D) {
			half d = 0;

			half3 transmittance = half3(1, 1, 1);
			half3 shadowRay = p + D*d;
			half density = 0; 
			int iterations = 0;
			while(mapScene(shadowRay)<0)
			{
				d += shadowStep;
				
				density = getDensity(shadowRay +_Time[1]);
				transmittance *= exp(-extintion*density*shadowStep);
			
				shadowRay = p + D*d;
				iterations++;
				

			}
			return transmittance;
		}

	

		half mapScene(half3 p) {
			half b= sdBox(p , half3(5,2.5,5));
			return b;
		}
		
		float henyey_greenstein_phase_func(float mu)
		{
			// Henyey-Greenstein phase function factor [-1, 1]
			// represents the average cosine of the scattered directions
			// 0 is isotropic scattering
			// > 1 is forward scattering, < 1 is backwards
			const float g = 0.76;

			return
				(1. - g*g)/((4. + PI) * pow(1. + g*g - 2.*g*mu, 1.5));
		}

		fragOutput frag(fragInput IN)
		{
			half3 D = normalize(IN.D);//getWorldUV(IN.UV.xy));
			Ray r = initRay(O, D);
			int steps = 0;

			fragOutput Out;
			half f = _FValue;
			

#if defined(LERP_RAYMARCH)
			half dist = marchSceneLerpSort(r, _MaxMarchingSteps, _Epsilon, steps);
#elif defined(BISECTION_RAYMARCH)
			half dist = marchSceneBisection(r, _MaxMarchingSteps, _Epsilon, steps);
#elif defined(SECANT_RAYMARCH)
			half dist = marchSceneSecant(r, _MaxMarchingSteps, _Epsilon, steps);
#else

			half dist = marchScene(r, _MaxMarchingSteps, _Epsilon, steps);

#endif 

	
		    clip(Far-dist-_Epsilon	);

			half3 p = getRayPoint(r, dist);



			
			half density = 0;
			half dt = 0.05;
			half d = 0.1;
			half shadowTransmittance;


			half3 transmittance = half3(1.0,1.0,1.0);
			half3 auxp = getRayPoint(r, dist + d);
			half3 LD = _WorldSpaceLightPos0.xyz;
			half3 LC = _LightColor0.rgb;
			half3 scatteringEvents = half3(0, 0, 0);

			float alpha = 1;
			int iterations = 0;
			while((mapScene(auxp)<0 ))
			{
							
				density = getDensity(auxp +  _Time[1]);
				shadowTransmittance = getShadowVolumeTransmitance(0.05, auxp, LD);
				transmittance *= exp(-density * extintion * dt);
				
				scatteringEvents += density*transmittance*scattering* shadowTransmittance * dt
									* LC*henyey_greenstein_phase_func(_Mix);
				
				d += dt;
				auxp = getRayPoint(r, dist + d);
				iterations++;
				

			}
		

			half4 val = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, D);
			half3 skyColor = DecodeHDR(val, unity_SpecCube0_HDR);
			Out.col.rgb = transmittance*skyColor +scatteringEvents;
			Out.col.rgb =  pow(Out.col.rgb, float3(1, 1, 1)*1.0 / 2.2);
			Out.col.a = 1 - transmittance;
			
	


			half4 projP = mul(UNITY_MATRIX_VP, half4(auxp.xyz, 1));
			half depth = projP.z / projP.w;

#if defined(UNITY_REVERSED_Z)
			Out.depth = depth;
#else
			Out.depth = 1-depth	;
#endif

			//Out.col = dist/Far;
			//Out.col.a = 1;
			return Out;
		
		}
		


		
		ENDCG

		}
	}

	CustomEditor "FullScreenQuadGUI"

}
