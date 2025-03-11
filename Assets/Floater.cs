using UnityEngine;

public class Floater : MonoBehaviour
{
    public Rigidbody rb; // Rigidbody of the floating object
    public Transform waterBlock; // Assign the water block in the Inspector
    public float buoyancyStrength = 10f; // Strength of the floating effect
    public float waterDrag = 2f; // Slows movement in water
    public float waterAngularDrag = 1f; // Reduces rotation in water

    private void FixedUpdate()
    {
        if (waterBlock == null || rb == null)
            return; // Ensure references exist

        float waterTop = waterBlock.position.y + (waterBlock.localScale.y / 2f); // Get top surface of the block
        float objectBottom = transform.position.y - (transform.localScale.y / 2f); // Get bottom of the boat

        // If the boat is partially or fully submerged
        if (objectBottom < waterTop)
        {
            float depth = waterTop - objectBottom; // How deep the boat is submerged
            float buoyancyForce = Mathf.Clamp01(depth) * buoyancyStrength;

            // Apply buoyancy force upwards
            rb.AddForce(Vector3.up * buoyancyForce, ForceMode.Acceleration);

            // Apply drag to slow movement in water
            rb.linearVelocity *= 1f - (waterDrag * Time.fixedDeltaTime);
            rb.angularVelocity *= 1f - (waterAngularDrag * Time.fixedDeltaTime);
        }
        else
        {
            // If the boat is above water, let gravity pull it down naturally
            rb.AddForce(Vector3.down * Physics.gravity.y, ForceMode.Acceleration);
        }
    }
}
