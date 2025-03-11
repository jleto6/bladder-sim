using UnityEngine;

public class WaterScale : MonoBehaviour
{
    public float speed = 0.4f; // Speed of rising and scaling
    public Transform water;
    public Transform bladder;

    private float targetWaterScaleY;
    private Vector3 targetWaterPosition;

    private float targetBladderScaleY;
    private Vector3 targetBladderPosition;

    private float velocityWaterScale = 0f;
    private float velocityWaterPosition = 0f;
    
    private float velocityBladderScale = 0f;
    private float velocityBladderPosition = 0f;

    private float smoothTime = 0.4f; // Adjust for smoother/slower water movement
    private float bobbingStrength = 0.02f; // Small fluid-like bobbing effect

    private void Start()
    {
        targetWaterScaleY = water.localScale.y;
        targetWaterPosition = water.position;

        if (bladder != null)
        {
            targetBladderScaleY = bladder.localScale.y;
            targetBladderPosition = bladder.position;
        }
    }

    private void Update()
    {
        if (Input.GetKey(KeyCode.UpArrow))
        {
            targetWaterScaleY += speed * Time.deltaTime;
            targetWaterPosition += Vector3.up * (speed * 0.5f * Time.deltaTime);

            if (bladder != null)
            {
                targetBladderScaleY += speed * Time.deltaTime;
                targetBladderPosition += Vector3.up * (speed * 0.5f * Time.deltaTime);
            }
        }
        else if (Input.GetKey(KeyCode.DownArrow))
        {
            // Ensure we don't reference bladder properties if bladder is null
            if (targetWaterScaleY > 0.1f || (bladder != null && targetBladderScaleY > 0.1f))
            {
                targetWaterScaleY -= speed * Time.deltaTime;
                targetWaterPosition -= Vector3.up * (speed * 0.5f * Time.deltaTime);

                if (bladder != null)
                {
                    targetBladderScaleY -= speed * Time.deltaTime;
                    targetBladderPosition -= Vector3.up * (speed * 0.5f * Time.deltaTime);
                }
            }
        }

        // Add a small natural bobbing effect to the target position
        float bobbingOffset = Mathf.Sin(Time.time * 2.0f) * bobbingStrength;

        // Smoothly interpolate water scale and position using SmoothDamp for soft motion
        float newScaleY = Mathf.SmoothDamp(water.localScale.y, targetWaterScaleY, ref velocityWaterScale, smoothTime);
        float newPosY = Mathf.SmoothDamp(water.position.y, targetWaterPosition.y + bobbingOffset, ref velocityWaterPosition, smoothTime);

        water.localScale = new Vector3(water.localScale.x, newScaleY, water.localScale.z);
        water.position = new Vector3(water.position.x, newPosY, water.position.z);

        if (bladder == null) return;

        // Smoothly interpolate bladder scale and position using SmoothDamp
        float newBladderScaleY = Mathf.SmoothDamp(bladder.localScale.y, targetBladderScaleY, ref velocityBladderScale, smoothTime);
        float newBladderPosY = Mathf.SmoothDamp(bladder.position.y, targetBladderPosition.y + bobbingOffset, ref velocityBladderPosition, smoothTime);

        bladder.localScale = new Vector3(bladder.localScale.x, newBladderScaleY, bladder.localScale.z);
        bladder.position = new Vector3(bladder.position.x, newBladderPosY, bladder.position.z);
    }
}
