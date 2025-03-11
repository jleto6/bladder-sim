using UnityEngine;
using System.Collections.Generic;

public class LowComputeWater : MonoBehaviour
{
    public GameObject particlePrefab;
    public int particleCount = 50;
    public Vector3 spawnArea = new Vector3(3, 2, 3);
    public float interactionRadius = 0.3f;
    public float separationStrength = 1.0f;
    public float gravityStrength = 9.81f;
    public LayerMask interactableLayer; // Set this to detect boats/bladders

    private List<GameObject> particles = new List<GameObject>();
    private Transform particleParent;

    void Start()
    {
        if (particlePrefab == null)
        {
            Debug.LogError("Particle Prefab is missing! Assign it in the Inspector.");
            return;
        }

        GameObject parentObj = new GameObject("WaterParticlesContainer");
        particleParent = parentObj.transform;

        SpawnParticles();
    }

    void FixedUpdate()
    {
        ApplyFluidPhysics();
    }

    void SpawnParticles()
    {
        for (int i = 0; i < particleCount; i++)
        {
            Vector3 spawnPos = transform.position + new Vector3(
                Random.Range(-spawnArea.x / 2, spawnArea.x / 2),
                Random.Range(0, spawnArea.y),
                Random.Range(-spawnArea.z / 2, spawnArea.z / 2)
            );

            GameObject particle = Instantiate(particlePrefab, spawnPos, Quaternion.identity, particleParent);
            particles.Add(particle);
        }
    }

    void ApplyFluidPhysics()
    {
        for (int i = 0; i < particles.Count; i++)
        {
            GameObject particle = particles[i];
            if (particle == null) continue;

            Vector3 totalSeparation = Vector3.zero;
            int neighborCount = 0;

            // Check particle-to-particle interactions
            for (int j = 0; j < particles.Count; j++)
            {
                if (i == j) continue;

                GameObject otherParticle = particles[j];
                Vector3 diff = particle.transform.position - otherParticle.transform.position;
                float distance = diff.magnitude;

                if (distance < interactionRadius && distance > 0.01f)
                {
                    totalSeparation += diff.normalized / distance; 
                    neighborCount++;
                }
            }

            // Apply smooth separation
            if (neighborCount > 0)
            {
                Vector3 separationForce = (totalSeparation / neighborCount) * separationStrength;
                particle.transform.position += separationForce * Time.fixedDeltaTime;
            }

            // Apply gravity
            particle.transform.position += Vector3.down * gravityStrength * Time.fixedDeltaTime;

            // **NEW: Check for interactions with boats/bladders**
            Collider[] colliders = Physics.OverlapSphere(particle.transform.position, interactionRadius, interactableLayer);
            foreach (Collider col in colliders)
            {
                Vector3 awayFromObject = (particle.transform.position - col.transform.position).normalized;
                particle.transform.position += awayFromObject * separationStrength * Time.fixedDeltaTime;
            }
        }
    }
}
