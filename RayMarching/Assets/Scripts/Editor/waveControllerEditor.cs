using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
[CustomEditor(typeof(waveController))]
[CanEditMultipleObjects]
public class waveControllerEditor : Editor
{

    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        waveController myScript = (waveController)target;
        if (GUILayout.Button("SendWaves"))
        {
            myScript.Init();
        }
    }
}
