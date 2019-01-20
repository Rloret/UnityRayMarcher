using UnityEditor;
using UnityEngine;
using System;

public enum RaymarchType
{
    BISECTION_RAYMARCH,SECANT_RAYMARCH,VANILLA_RAYMARCH, LERP_RAYMARCH,
}

public enum DebugRender
{
    CONVERGENCE,NORMALS, LIGHTING,DISTANCE
}
public class FullScreenQuadGUI : ShaderGUI {


   [Space] public RaymarchType RaymarchAlgorithm;
   [Space] public DebugRender DebugType;
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material targetMat = materialEditor.target as Material;


        EditorGUI.BeginChangeCheck();
        RaymarchAlgorithm = (RaymarchType)EditorGUILayout.EnumPopup("Marching to use", RaymarchAlgorithm);
        DebugType = (DebugRender)EditorGUILayout.EnumPopup("Debug?", DebugType);
        if (EditorGUI.EndChangeCheck())
        {
            var names = Enum.GetNames(typeof(RaymarchType));
            foreach (var name in names)
            {
                if (name.Equals(RaymarchAlgorithm.ToString()))
                {
                    targetMat.EnableKeyword(name);
                }
                else
                {
                    targetMat.DisableKeyword(name);
                }
            }
            names = Enum.GetNames(typeof(DebugRender));

            foreach (var name in names)
            {
                if (name.Equals(DebugType.ToString()))
                {
                    targetMat.EnableKeyword(name);
                }
                else
                {
                    targetMat.DisableKeyword(name);
                }
            }

        }
        base.OnGUI(materialEditor, properties);

       
    }
}
