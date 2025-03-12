using UnityEngine;
using TMPro;


public class Data : MonoBehaviour
{
    public TMP_Text volumeText; // Assign in Inspector
    public TMP_Text speedText; // Assign in Inspector
    public TMP_Text bladderText; // Assign in Inspector
    public TMP_Text powerText; // Assign in Inspector

    public void Update()
    {
        volumeText.text = "Freshwater Volume: " + GlobalVariables.waterVolume.ToString() + " m³";

        bladderText.text = "Bladder Volume: " + GlobalVariables.bladderVolume.ToString() + " m³";

        speedText.text = "Time to Fill: " + ((Mathf.Round((420/GlobalVariables.speed) * 10)/ 10) / 60).ToString() + " minutes";

        powerText.text = "Power Needed: ~" + (132 * GlobalVariables.speed).ToString() + " kW";

    }

    public WaterScale waterScale; 

    public void OnButtonClick()
    {
        Debug.Log("Button clicked!");
        waterScale.RaiseWater();
    
    }

    public void updateSlider(float value){
    
        GlobalVariables.speed = value;
        //Debug.Log(GlobalVariables.speed);
    }
}
