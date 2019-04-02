
uniform float _AuxValue;


struct Ray {
	float3 o;
	float3 d;
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
	
	//R- right U-Up F-Forward basis vectors of the camera.
	m_pixels.xyz =  m_pixels.x * normalize(R) + normalize(U) * m_pixels.y + normalize(-F) * m_pixels.z;


	return m_pixels.xyz ;
}


float3 getRayPoint(Ray r, float t)
{
	return r.o + r.d*t;
}

float sdSphere(float3 samplePoint,float r) {
	return (length(samplePoint) - r);
}
float sdPlane(float3 P, float3 N)
{
	const float width = 10;
	//return  abs(dot(P, N.xyz))- width*0.5;

	return  dot(P, N.xyz);
}

float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return length(max(d, 0.0))
		+ min(max(d.x, max(d.y, d.z)), 0.0); // remove this line for an only partially signed sdf 
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

float opIntersection(float d1, float d2) { return max(d1, d2); }

// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float opModPolar(inout float2 p, float repetitions) {
	float angle = 2 * PI / repetitions;
	float a = atan2(p.y, p.x) + angle / 2.;
	float r = length(p);
	float c = floor(a / angle);
	a = fmod(a, angle) - angle / 2.;
	p = float2(cos(a), sin(a))*r;
	// For an odd number of repetitions, fix cell index of the cell in -x direction
	// (cell index would be e.g. -5 and 5 in the two halves of the cell):
	if (abs(c) >= (repetitions / 2)) c = abs(c);
	return c;
}

float3 opRep( float3 p,float3 c)
{
	float3 q = fmod(p, c) - 0.5*c;
	return q;
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

float marchSceneBisection(Ray r, half MaxSteps, half EPSILON, out int steps) {
	float currDist = Near;
	float farDist =Far;
	float3 farpoint = getRayPoint(r, farDist);
	float h_a = mapScene(getRayPoint(r,currDist));
	float h_b = mapScene(farpoint);
	steps = 0;

	//march at fixed rate if not possible to guarantee a solution
	//if ( farpoint.y>100 ||h_a*h_b > 0) return Far;
	if (sign(h_a) != sign(h_b)) {
		return marchScene(r, MaxSteps, EPSILON, steps);
	}

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
	float x1 = planeIntersection(r, float3(0, 1, 0));

	float3 farpoint = getRayPoint(r, x1);
	float h_x0 = mapScene(getRayPoint(r, x0));
	float h_x1 = mapScene(getRayPoint(r, x1));

	
	steps = steps;
	float x2=0;

	//march normal if cant guarantee a solution
	//if (farpoint.y>100 || h_x0*h_x1 > 0) return Far;
	if (sign(h_x0) != sign(h_x1)) {
		return marchScene(r, MaxSteps, EPSILON, steps);
	}

	while (steps < MaxSteps)
	{
		steps++;

		h_x0 = mapScene(getRayPoint(r, x0));
		h_x1 = mapScene(getRayPoint(r, x1));

		x2 = x1 - ((h_x1*(x1 - x0)) / (h_x1 - h_x0));
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


