using UnityEngine;
using UnityEngine.Rendering.Universal;

[System.Serializable]
public class GlitchPostProcess : ScriptableRendererFeature
{
    [SerializeField] private Shader _shader;
    [SerializeField] private PostprocessTiming _timing = PostprocessTiming.AfterOpaque;
    [SerializeField] private bool _applyToSceneView = true;

    private GlitchPostProcessPass _postProcessPass;

    public override void Create()
    {
        Debug.Log("Create1");
        _postProcessPass = new GlitchPostProcessPass(_applyToSceneView, _shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        Debug.Log("AddRenderPasses");
        _postProcessPass.Setup(renderer.cameraColorTarget, _timing);
        renderer.EnqueuePass(_postProcessPass);
    }
}
