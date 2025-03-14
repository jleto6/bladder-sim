using UnityEngine;

public class WaterScale : MonoBehaviour
{
    public Transform water;
    public Transform bladder;

    public Vector3 waterScaleMultiplier = Vector3.one; // Set these in the Inspector
    public Vector3 bladderScaleMultiplier = Vector3.one;

    public float speedUp = 10;
    public float targetHeight = 2.0f; // Target height to raise to 
    public float raiseDuration = 420; // Time to reach target 
    private float baseDuration = 420;

    private float targetWaterScaleY;
    private Vector3 targetWaterPosition;
    private float targetBladderScaleY;
    private Vector3 targetBladderPosition;
    private float velocityWaterScale = 0f;
    private float velocityWaterPosition = 0f;

    private float velocityBladderScale = 0f;
    private float velocityBladderPosition = 0f;
    private float smoothTime = 0.4f; // smoother water movement
    private float bobbingStrength = 0.02f; // Small bobbing effect
    private bool isRaising = false;
    private float raiseTimer = 0f;
    private float initialWaterScaleY;
    private Vector3 initialWaterPosition;
    private float initialBladderScaleY;
    private Vector3 initialBladderPosition;

    private void Start()
    {
        raiseDuration = raiseDuration / speedUp;
        baseDuration = baseDuration / speedUp;

        targetWaterScaleY = water.localScale.y;
        targetWaterPosition = water.position;
        initialWaterScaleY = targetWaterScaleY;
        initialWaterPosition = targetWaterPosition;

        if (bladder != null)
        {
            targetBladderScaleY = bladder.localScale.y;
            targetBladderPosition = bladder.position;
            initialBladderScaleY = targetBladderScaleY;
            initialBladderPosition = targetBladderPosition;
        }
    }

    public void RaiseWater()
    {
        isRaising = true;
        raiseTimer = 0f;
    }

    private float lastSpeed = 1;

    private void Update()
    {
        if (lastSpeed != GlobalVariables.speed)
        {
            raiseDuration = baseDuration / GlobalVariables.speed;
            lastSpeed = GlobalVariables.speed;
        }

        if (isRaising)
        {
            raiseTimer += Time.deltaTime;
            float progress = raiseTimer / raiseDuration;

            if (progress >= 1.0f)
            {
                progress = 1.0f;
                isRaising = false;
            }

            targetWaterScaleY = Mathf.Lerp(initialWaterScaleY, initialWaterScaleY + targetHeight, progress);
            targetWaterPosition = Vector3.Lerp(initialWaterPosition, initialWaterPosition + Vector3.up * (targetHeight * 0.5f), progress);

            if (bladder != null)
            {
                targetBladderScaleY = Mathf.Lerp(initialBladderScaleY, initialBladderScaleY + targetHeight, progress);
                targetBladderPosition = Vector3.Lerp(initialBladderPosition, initialBladderPosition + Vector3.up * (targetHeight * 0.5f), progress);
            }
        }

        // Bobbing effect
        float bobbingOffset = Mathf.Sin(Time.time * 2.0f) * bobbingStrength;

        // Smooth scaling and movement for water
        float newScaleY = Mathf.SmoothDamp(water.localScale.y, targetWaterScaleY, ref velocityWaterScale, smoothTime);
        float newPosY = Mathf.SmoothDamp(water.position.y, targetWaterPosition.y + bobbingOffset, ref velocityWaterPosition, smoothTime);

        water.localScale = new Vector3(
            waterScaleMultiplier.x * water.localScale.x,
            waterScaleMultiplier.y * newScaleY,
            waterScaleMultiplier.z * water.localScale.z
        );
        water.position = new Vector3(water.position.x, newPosY, water.position.z);

        if (bladder == null) return;

        // Smooth scaling and movement for bladder
        float newBladderScaleY = Mathf.SmoothDamp(bladder.localScale.y, targetBladderScaleY, ref velocityBladderScale, smoothTime);
        float newBladderPosY = Mathf.SmoothDamp(bladder.position.y, targetBladderPosition.y, ref velocityBladderPosition, smoothTime);

        bladder.localScale = new Vector3(
            bladderScaleMultiplier.x * bladder.localScale.x,
            bladderScaleMultiplier.y * newBladderScaleY,
            bladderScaleMultiplier.z * bladder.localScale.z
        );
        bladder.position = new Vector3(bladder.position.x, newBladderPosY, bladder.position.z);
    }
}
