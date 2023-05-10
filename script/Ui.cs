using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.UI;

public class Ui : MonoBehaviour
{
    public float lightRotation;
    public Material material;

    
    
    
    public RotateLight rl;
    [SerializeField] private Slider lightslider;
    [Header("Generallobe0")]
    [SerializeField] private Slider Generallobe0slider;
    [SerializeField] private TMP_Text Generallobe0text;
    [Header("Generallobe1")]
    [SerializeField] private Slider Generallobe1slider;
    [SerializeField] private TMP_Text Generallobe1text;
    
    [Header("Noselobe0")]
    [SerializeField] private Slider Noselobe0slider;
    [SerializeField] private TMP_Text Noselobe0text;
    [Header("Noselobe1")]
    [SerializeField] private Slider Noselobe1slider;
    [SerializeField] private TMP_Text Noselobe1text;
    
    [Header("Foreheadlobe0")]
    [SerializeField] private Slider Foreheadlobe0slider;
    [SerializeField] private TMP_Text Foreheadlobe0text;
    [Header("Foreheadlobe1")]
    [SerializeField] private Slider Foreheadlobe1slider;
    [SerializeField] private TMP_Text Foreheadlobe1text;
    
    [Header("Mouselobe0")]
    [SerializeField] private Slider Mouselobe0slider;
    [SerializeField] private TMP_Text Mouselobe0text;
    [Header("Mouselobe1")]
    [SerializeField] private Slider Mouselobe1slider;
    [SerializeField] private TMP_Text FMouselobe1text;
    
    [Header("Lip")]
    [SerializeField] private Slider Lipslider;
    [SerializeField] private TMP_Text Liptext;
    
    [Header("LipRoughness")]
    [SerializeField] private Slider LipsRlider;
    [SerializeField] private TMP_Text LipRtext;
    // Start is called before the first frame update
    void Start()
    {
       
    }

    // Update is called once per frame
    void Update()
    {

        
        rl.rotation = lightslider.value;
        material.SetFloat("_Lobe0Roughness",Generallobe0slider.value );
        Generallobe0text.text = Generallobe0slider.value.ToString("0.00");
        material.SetFloat("_Lobe1Roughness",Generallobe1slider.value );
        Generallobe1text.text = Generallobe1slider.value.ToString("0.00");
        
        material.SetFloat("_NoseLobe0Roughness",Noselobe0slider.value );
        Noselobe0text.text = Noselobe0slider.value.ToString("0.00");
        
        material.SetFloat("_NoseLobe1Roughness",Noselobe1slider.value );
        Noselobe1text.text = Noselobe1slider.value.ToString("0.00");
        
        material.SetFloat("_foreheadLobe0Roughness",Foreheadlobe0slider.value );
        Foreheadlobe0text.text = Foreheadlobe0slider.value.ToString("0.00");
        
        material.SetFloat("_foreheadLobe1Roughness",Foreheadlobe1slider.value );
        Foreheadlobe1text.text = Foreheadlobe1slider.value.ToString("0.00");
        
        material.SetFloat("_mouseLobe0Roughness",Mouselobe0slider.value );
        Mouselobe0text.text = Mouselobe0slider.value.ToString("0.00");
        
        material.SetFloat("_mouseLobe1Roughness",Mouselobe1slider.value );
        FMouselobe1text.text = Mouselobe1slider.value.ToString("0.00");
        
        material.SetFloat("_ClearCoat",Lipslider.value );
        Liptext.text = Lipslider.value.ToString("0.00");
        
        material.SetFloat("_ClearCoatRoughness",LipsRlider.value );
        LipRtext.text = LipsRlider.value.ToString("0.00");
    }


}
