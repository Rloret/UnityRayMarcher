using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class WorleyGen : MonoBehaviour
{
    public RenderTexture RT;
    public Material _3DrenderViewer;
    public ComputeShader worleyShader;
    private Texture3D copy;

    ComputeBuffer pixelsBuffer;

    public int textureDimensions = 256;
    private readonly int threadblock = 8;

    [ContextMenu("Dispatch")]
    public void dispatch()
    {

        RT = new RenderTexture(textureDimensions, textureDimensions,0, RenderTextureFormat.ARGB32,RenderTextureReadWrite.Linear);
        RT.enableRandomWrite = true;
        RT.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        RT.volumeDepth = textureDimensions;
        RT.wrapMode = TextureWrapMode.Mirror;
        RT.Create();
       
       

        worleyShader.SetTexture(0, "worleyBuff", RT);
       

       // AssetDatabase.CreateAsset(RT, "Assets/3DTextures/worley.asset");
        _3DrenderViewer.SetTexture("_CloudNoise", RT);
        worleyShader.Dispatch(0, RT.width/threadblock, RT.height / threadblock, RT.volumeDepth / threadblock);


    }
}
