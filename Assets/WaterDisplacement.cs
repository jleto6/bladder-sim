using UnityEngine;

public class WaterDisplacement : MonoBehaviour
{
    public Collider waterObject; // Assign the water object's collider in the Inspector   
 
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
            Debug.Log($"Volume: {volume} m³");

            
        }
        else
        {
            Debug.LogWarning("Water object is not assigned!");
        }

    }

    private void Update()
    {



    }

}
