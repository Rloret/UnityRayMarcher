using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class cameraMovement : MonoBehaviour {

    [SerializeField] float Speed;
    [SerializeField] float rotateSpeed;
    public bool drawGiz;

    private void OnDrawGizmosSelected()
    {
        
        if (drawGiz)
        {
            Camera cam = Camera.main;
            Matrix4x4 glmat = GL.GetGPUProjectionMatrix(cam.projectionMatrix,false);
            Matrix4x4 camat = cam.projectionMatrix;

            float z = camat.m23 / (camat.m22 - 1);
            float farz = (z * (-camat.m22 + 1))/(-1- camat.m22);//((cam.projectionMatrix.m22 - 1.0f) * z) / (cam.projectionMatrix.m22 + 1.0f);
          //  Debug.Log("N: " + n + " " + "F: " + f  + "f-n: " + (f-n) + " n-f: " +(n-f));
            if (cam.pixelHeight>40|| cam.pixelWidth > 40)
            {
                Debug.LogError("The resolution is to high to display at realtime");
                return;
            }

            float halfH = Mathf.Abs(z / cam.projectionMatrix.m11);
            float halfW = Mathf.Abs(z / cam.projectionMatrix.m00);
           // Debug.Log(z + " " + halfH + " " + halfW);
            float delta =  (farz - z)/128;

            Vector3 O = new Vector3();
            Vector3 D = new Vector3();
            
            for (int col = 0; col < cam.pixelWidth; col++)
            {
                float u = (float)(col + 0.5f) / cam.pixelWidth;

                for (int row = 0; row < cam.pixelHeight; row++)
                {
                    
                    float v = (float)(row + 0.5f) / cam.pixelHeight;

                    Vector4 uv = new Vector4(u, v, 0, 1);
                    uv = uv * 2.0f - Vector4.one;
                    uv.z = z;
                    uv.y *= halfH;
                    uv.x *= halfW;

                    Vector3 F = -new Vector3(cam.worldToCameraMatrix.m20, cam.worldToCameraMatrix.m21, cam.worldToCameraMatrix.m22);// UNITY_MATRIX_V[2].xyz
                    F.Normalize();
                    Vector3 R =new Vector3(cam.worldToCameraMatrix.m00, cam.worldToCameraMatrix.m01, cam.worldToCameraMatrix.m02);
                    R.Normalize();
                    Vector3 U = new Vector3(cam.worldToCameraMatrix.m10, cam.worldToCameraMatrix.m11, cam.worldToCameraMatrix.m12);
                    U.Normalize();
                    Gizmos.color = Color.blue;
                    Gizmos.DrawLine(cam.transform.position, cam.transform.position+ F);
                    Gizmos.color = Color.red;
                    Gizmos.DrawLine(cam.transform.position, cam.transform.position + R);
                    Gizmos.color = Color.green;
                    Gizmos.DrawLine(cam.transform.position, cam.transform.position + U);
                    Vector3 worldUV = uv.x * R + U * uv.y + F * uv.z;
                    //UV = UV.normalized;
                    D = worldUV.normalized;

                    O = cam.transform.position+ worldUV;
                    Gizmos.color = new Color(0.2f, 0.2f, 0.2f, 0.2f);
                    Gizmos.DrawLine(O, O + D * farz);
                    float currd=0;
                    for (int i = 0; i < 96; i++)
                    {
                        Vector3 p =O+D*currd;
                        Gizmos.color = new Color(0.1f, 0f, 0, 0.1f);
                        Gizmos.DrawSphere(p, 0.1f);
                        //Gizmos.DrawSphere(p, 0.1f);
                        currd += mapScene(p,z,farz) *0.9f;
                        if (currd < 0) break;
                       
                       
                    }

                }

            }
        }
    }

    float mapScene(Vector3 p,float near,float far)
    {
        return sdfSphere(p,near,far);
      // return sampleWave(p,near,far);
    }

    float sdfSphere(Vector3 p,float near, float far)
    {
        float l = p.magnitude;
        float d = l - 1;
        if (l > far)
        {
            return far;
        }
        else if (d < 0.01)
        {
            Gizmos.color = new Color(0, 0.1f, 0, 0.1f);
            Gizmos.DrawSphere(p, 0.1f);
            return d;
        }



        return d;

    }
    float sampleWave(Vector3 p,float near,float far)
    {
        float h = getWaveHeight(p.x, p.z); //Mathf.PerlinNoise(p.x * 0.02f, p.z * 0.02f) * 50;
        float d = p.y - h;
        
        if (d> far)
        {
            return far;
        }
        else if (d < 0.01)
        {
            Gizmos.color = new Color(0, 0.1f, 0, 0.1f);
            Gizmos.DrawSphere(p, 0.1f);
            return d;

        }
        return d;
    }

    public float angle;
    public float height;
    public float width;


   float getWaveHeight(float x, float z){
       
        Vector2 D = (new Vector2(Mathf.Cos(angle* Mathf.PI  / 180.0f), Mathf.Sin(angle * Mathf.PI / 180.0f))).normalized;
        float k = Mathf.PI*2 / width;
        float inTrig = Vector2.Dot(k * D, new Vector2(x,z)) * k ;
        return height - Mathf.Abs(height * Mathf.Sin(inTrig));
    }

}
