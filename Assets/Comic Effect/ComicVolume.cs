using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[System.Serializable]
[VolumeComponentMenu("Comic Effect")]
public class ComicVolume : VolumeComponent
{
    public bool IsActive() => BlurRange.value > 0.0F;

    public FloatParameter BlurRange = new FloatParameter(1F);
    public Vector2Parameter BlurDirection = new Vector2Parameter(Vector2.one);
}
