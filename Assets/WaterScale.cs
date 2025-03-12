using UnityEngine;
public class WaterScale : MonoBehaviour
{
    public Transform water;
    public Transform bladder;
    public float speedUp = 10;
    public float targetHeight = 2.0f; // Target height to raise to (set in inspector)
    public float raiseDuration = 420; // Time to reach target (set in inspector)
    private float baseDuration = 420;

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
    
    // Call this function from a button
    public void RaiseWater()
    {
        isRaising = true;
        raiseTimer = 0f;
    }

    private float lastSpeed = 1;
    
    private void Update()
    {
        print(raiseDuration);

        if (lastSpeed != (GlobalVariables.speed)){
            raiseDuration = baseDuration / (GlobalVariables.speed);
            lastSpeed = (GlobalVariables.speed);
            print(raiseDuration);

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