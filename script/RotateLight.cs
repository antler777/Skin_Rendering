using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateLight : MonoBehaviour
{

    public float rotation = 0.0f;

    void Update()
    {
   
        transform.localRotation = Quaternion.Euler(0f,  rotation, 0f);
    }

}
