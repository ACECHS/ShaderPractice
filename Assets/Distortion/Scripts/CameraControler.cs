using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraControler : MonoBehaviour
{
    public float velocity = 1;
    public float sensitivity = 1;
    private Camera cam = null;
    private float v = 0;
    private float h = 0;
    private float up = 0;
    private float down = 0;
    void Start()
    {
        cam = gameObject.GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        v= Input.GetAxisRaw("Vertical");
        h = Input.GetAxisRaw("Horizontal");
        if (Input.GetKey(KeyCode.E))
            up = 1;
        else up = 0;
        if (Input.GetKey(KeyCode.Q))
            down = 1;
        else down = 0;
        gameObject.transform.localPosition += velocity*(cam.transform.right * h + cam.transform.forward * v+ cam.transform.up * up- cam.transform.up * down);
        gameObject.transform.localEulerAngles += new Vector3(-Input.GetAxis("Mouse Y"), Input.GetAxis("Mouse X"), 0)*sensitivity;
        
    }
}
