﻿
uniform float _AuxValue;

struct Ray {
	float3 o;
	float3 d;
};

struct HitInformation {
	half radius;
	half distance;
	half3 normal;
};

Ray initRay(float3 o, float3 D) {
	Ray r;
	r.o = o;
	r.d = D;
	return r;
}



float2 computeNearPlaneDimensions() {
	//float near = Proj//UNITY_MATRIX_P._m23 / (UNITY_MATRIX_P._m22 - 1.0);
	float halfH = abs(Near / UNITY_MATRIX_P._m11);
	float halfW = abs(Near / UNITY_MATRIX_P._m00);

	return float2(halfW, halfH);

}
float3 getWorldUV(float2 uv) 
{

	float2 nearDims = computeNearPlaneDimensions();
	float3 m_pixels = float3(uv * 2. - 1.,Near );

	m_pixels.x *= nearDims.x;
	m_pixels.y *= nearDims.y;
	
	m_pixels.xyz =  m_pixels.x * normalize(R) + normalize(U) * m_pixels.y + normalize(-F) * m_pixels.z;


	return m_pixels.xyz ;
}


float3 getRayPoint(Ray r, float t)
{
	return r.o + r.d*t;
}

float sdSphere(float3 samplePoint) {
	return length(samplePoint) -200;
}
float sdPlane(float3 P, float3 N)
{
	const float width = 10;
	//return  abs(dot(P, N.xyz))- width*0.5;

	return  dot(P, N.xyz);
}

float sdTorus(float3 p, float2 t)
{
	float2 q = float2(length(p.xz) - t.x, p.y);
	return length(q) - t.y;
} 

float sdWave(float3 p) {
	float height = F_z(p);//F0_z(p, (int)_AuxValue);// F_z(p);// F0_z(p, (int)_AuxValue); +
	return p.y - height;
}

float opSmoothUnion(float d1, float d2, float k) {
	float h = clamp(0.5 + 0.5*(d2 - d1) / k, 0.0, 1.0);
	return lerp(d2, d1, h) - k * h*(1.0 - h);
}

float opSmoothSubtraction(float d1, float d2, float k) {
	float h = clamp(0.5 - 0.5*(d2 + d1) / k, 0.0, 1.0);
	return lerp(d2, -d1, h) + k * h*(1.0 - h);
}

float opSmoothIntersection(float d1, float d2, float k) {
	float h = clamp(0.5 - 0.5*(d2 - d1) / k, 0.0, 1.0);
	return lerp(d2, d1, h) + k * h*(1.0 - h);
}
float mapScene(float3 p) {
	//return sdfSphere(p+ float3(0,0, _AuxValue));
	float wDist = sdWave(p);
	
	float sDist = sdSphere(p+sin(_Time[2]/10)*float3(0,500,0));
	//return sDist;
	//return opSmoothUnion(sDist, wDist,100);
	return wDist;
}
float marchScene(Ray r,half MaxSteps,half EPSILON,out int steps) {
	float currDist = Near;
	for (int i = 0; i < MaxSteps; i++)
	{
		float3 p = getRayPoint(r, currDist);
		float closestDistance = mapScene(p);
		steps = i;
		if (closestDistance < EPSILON) {

			return currDist;
		}
		currDist += closestDistance*0.9;
		if (currDist >= Far)			return Far;
		
	}
	return currDist;
}
float planeIntersection(Ray r, float3 N) {
	float denom = dot(r.d, N);
	if (denom == 0) {
		return Far;

	}
	else {
		return -(dot(r.o, N) ) / denom;

	}
}

float marchSceneBisection(Ray r, half MaxSteps, half EPSILON, out int steps) {
	float currDist = Near;
	float farDist =Far;
	float h_a = mapScene(getRayPoint(r,currDist));
	float h_b = mapScene(getRayPoint(r, farDist));


	
	//if (h_a*h_b > 0) return Far;

	while (steps < MaxSteps)
	{
		steps++;
		float middleDist = (farDist + currDist)*0.5;
		float h_c = mapScene(getRayPoint(r, middleDist));
		if (abs(h_c) < EPSILON)return middleDist;
		
		if (h_c > 0) currDist = middleDist;
		else		 farDist = middleDist;

	}
	
	return Far;
}


float marchSceneSecant(Ray r, half MaxSteps, half EPSILON, out int steps) {
	float x0 = Near;
	float x1 = Far;//planeIntersection(r, float3(0, 1, 0));
	float h_x0 = mapScene(getRayPoint(r, x0));
	float h_x1 = mapScene(getRayPoint(r, x1));
	if (abs(h_x0) < abs(h_x1)) {
		double aux = x0;
		x0 = x1;
		x1 = aux;
	}

	float x2=0;
//	if (h_a*h_b > 0) return Far;

	while (steps < MaxSteps)
	{
		steps++;

		h_x0 = mapScene(getRayPoint(r, x0));
		h_x1 = mapScene(getRayPoint(r, x1));

		x2 = x1 - (h_x1*(x0 - x1) / (h_x0 - h_x1));
		x0 = x1;
		x1 = x2;
		if (abs(mapScene(getRayPoint(r, x1))) < EPSILON) {
			return x1;
		}

	}

	return Far;
}



float marchSceneLerpSort(Ray r, half MaxSteps, half EPSILON, out int steps) {
	float tm = Near;
	float tx = Far;
	float hx = mapScene(getRayPoint(r, tx));
	if (hx > 0.0) return tx;
	float hm = mapScene(getRayPoint(r, tm));
	float tmid = 0.0;
	for (int i = 0; i < MaxSteps; i++) {
		tmid = lerp(tm, tx, hm / (hm - hx));
		steps++;
		float3 p = getRayPoint(r, tmid);
		float hmid = mapScene(p);
		if (hmid < 0.0) {
			tx = tmid;
			hx = hmid;
		}
		else {
			tm = tmid;
			hm = hmid;
		}
	}
	return tmid;
}


//float march(Ray r, half MaxSteps, half MaxDistance, half EPSILON) {
//	float depth = 0;
//	for (int i = 0; i < MaxSteps; i++) {
//		float3 p = getRayPoint(r, depth);
//		float dist = mapScene(p);
//		if (dist < EPSILON) {
//			return depth;
//		}
//		depth += dist;
//		if (depth >= MaxDistance) {
//			return MaxDistance;
//		}
//	}
//	return MaxDistance;
//}

float3 estimateNormal(float3 p,float EPSILON) {

	float3 d =float3(EPSILON, 0, -EPSILON);

	return normalize(float3(
							mapScene(p+d.xyy) -  mapScene(p+d.zyy),
							mapScene(p+d.yxy) -  mapScene(p+d.yzy),
							mapScene(p+d.yyx) -  mapScene(p+d.yyz)
						   ));
}
float queryScene(float3 p) {
	return 0;
}


