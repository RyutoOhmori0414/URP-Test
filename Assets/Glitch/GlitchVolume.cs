using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;


[Serializable]
[VolumeComponentMenu("Glitch Effect")]
public class GlitchVolume : VolumeComponent
{
    public bool IsActive() => LineColorParamator != Color.white;

    public ColorParameter LineColorParamator = new ColorParameter(Color.white);
    [Range(0.0f, 10.0f)]
    public FloatParameter LineSpeedParamator = new FloatParameter(0.1f);
    [Range(0.0f, 1f)]
    public FloatParameter LineSizeParamator = new FloatParameter(0.01f);
    [Range(0.0f, 1.0f)]
    public FloatParameter ColorGapParamater = new FloatParameter(0.01f);
    [Range(0.0f, 30.0f)]
    public FloatParameter FrameRateParamater = new FloatParameter(15f);
    [Range(0.0f, 1.0f)]
    public FloatParameter FrequencyParamater = new FloatParameter(0.1f);
    [Range(1.0f, 10.0f)]
    public FloatParameter GlitchScaleParamater = new FloatParameter(1.0f);
}
