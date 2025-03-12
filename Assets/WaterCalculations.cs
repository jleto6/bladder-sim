using UnityEngine;


public class WaterCalculations : MonoBehaviour
{
    public Collider waterObject; // Assign the water object's collider in the Inspector 
    public Collider bladderObject; // Assign the bladder object's collider in the Inspector  
 
    private float real_length = 305f;
    private float real_width = 33.5f;  
    private float real_depth = 12.5f; 


    private void Start()
    {
        // Get surface area of water
        if (waterObject != null)
        {
        
            // Get the bounds of the water object's collider
            float width = waterObject.bounds.size.x;
            float length = waterObject.bounds.size.z *(2);
            float depth = waterObject.bounds.size.y;
        

            // Calculate and volume of the water
            float volume = length * width * depth;
            volume = volume * 16500; //proportional scaling

            GlobalVariables.waterVolume = Mathf.Round(volume);
            Debug.Log($"Volume: {GlobalVariables.waterVolume} m³");

        }
        
        

    }

    private void Update()
    {

        float bladderVolume = 0;
        // Get surface area of bladder
        if (bladderObject != null)
        {
        
            // Get the bounds of the water object's collider
            float bladderWidth = bladderObject.bounds.size.x;
            float bladderLength = bladderObject.bounds.size.z *(2);
            float bladderDepth = bladderObject.bounds.size.y;
        

            // Calculate and volume of the water
            bladderVolume = bladderWidth * bladderLength * bladderDepth;
            bladderVolume = bladderVolume * 16500; // proportional scaling

            GlobalVariables.bladderVolume = Mathf.Round(bladderVolume);

        }


    }

}
