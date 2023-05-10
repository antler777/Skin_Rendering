using UnityEngine;

public class CameraMove : MonoBehaviour
{
    public float moveSpeed = 10f;  
    public float zoomSpeed = 20f;   

    void Update()
    {
        
        float horizontal = Input.GetAxis("Horizontal");
        float vertical = Input.GetAxis("Vertical");
        Vector3 moveDirection = new Vector3(horizontal, vertical, 0.0f);
        transform.Translate(moveDirection * moveSpeed * Time.deltaTime);

     
        float zoom = Input.GetAxis("Mouse ScrollWheel");
        Vector3 zoomDirection = new Vector3(0.0f, 0.0f, zoom);
        transform.Translate(zoomDirection * zoomSpeed * Time.deltaTime);
    }
}