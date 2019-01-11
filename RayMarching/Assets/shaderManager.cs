using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class shaderManager : MonoBehaviour {

    public Material FSQ;
    [ContextMenu("UpdateMenu")]
    public void FixedUpdate()
    {
        FSQ.SetMatrix("u_invV", Camera.main.cameraToWorldMatrix);
    }
    // Update is called once per frame
    void Update () {
        FSQ.SetMatrix("u_invV", Camera.main.cameraToWorldMatrix);
	}

    private void OnValidate()
    {
        FSQ.SetMatrix("u_invV", Camera.main.cameraToWorldMatrix);
    }

    private void OnDrawGizmos()
    {
        float x = 256;
        float y = 512;

    }

    
}
