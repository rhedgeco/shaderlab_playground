using UnityEngine;

public class MouseRotator : MonoBehaviour
{
    [SerializeField] private float sensitivity = 2f;

    void Update()
    {
        if (Input.GetMouseButton(0))
        {
            float x = Input.GetAxis("Mouse X") * sensitivity;
            float y = Input.GetAxis("Mouse Y") * sensitivity;
            transform.Rotate(Vector3.up, x, Space.World);
            transform.Rotate(transform.right, -y, Space.World);
        }
    }
}