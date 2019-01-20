using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class waveController : MonoBehaviour {

    #region PublicVariables

    [Tooltip("This parameter controlls the direction in which the waves move")]
    [Range(0, 360)]
    public float _MainAngle;

    [Tooltip("This one adds a bit of variation over each wave Direction angle + Random(-span,span)")]
    [Range(0, 30)]
    public float _DirectionSpan;
    public float _Steepness;


    #endregion PublicVariables


    [System.Serializable]
    public struct Wave
    {
        public float Height;
        public float Width;
        public float Speed;
        public float Angle;


        public void initAngle(float random)
        {
            Angle += random;
        }
    };
    [Space]
    [Space]
    [Tooltip("This struct holds the basic information about a wave its amplitude(height), Wavelength(width) and speed")]
    public Wave[] _Waves;

    #region PrivateVariables
    ComputeBuffer waveBuffer;
    [SerializeField]Material Trochoid;

    #endregion PrivateVariables

    //The initialization consists in filling the buffer with data and giving values to the uniforms inside the shader.
    [ContextMenu("InitializeWaves")]
    public void Init () {
       // Trochoid = this.transform.GetComponent<MeshRenderer>().material;
        //Create the buffer here stride does not mean = opengl, stride= size of element in buffer.
        waveBuffer = new ComputeBuffer(_Waves.Length,  sizeof(float)*4 , ComputeBufferType.Default); //default=structured

       
        UpdateWavesInShader();

        
    }
    private void Start()
    {
        Init();
     }
    void Update()
    {
        //TODO: Overkill, change to GUI update or make a custom inspector.
       // UpdateWavesInShader();
    }

   private void OnValidate()
   {
    if(waveBuffer!=null)   UpdateWavesInShader();
   }


    void UpdateWavesInShader()
    {
        //Populate the buffer
        waveBuffer.SetData(_Waves);
        Trochoid.SetBuffer("waveBuffer", waveBuffer);

        Trochoid.SetInt("_NumWaves", _Waves.Length);
        Trochoid.SetFloat("_Steepness", _Steepness);
    }

    void OnDestroy()
    {
        waveBuffer.Dispose();

    }
}
