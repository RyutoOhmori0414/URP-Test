using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class ComicRenderFeature : ScriptableRendererFeature
{
    [SerializeField]
    private Shader _shader;
    [SerializeField]
    private PostProcessTiming _timing = PostProcessTiming.AfterOpaque;
    [SerializeField]
    private bool _applyToSceneView = true;

    private ComicRenderPass _postProcessPass;

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        _postProcessPass.Setup(renderer.cameraColorTarget, _timing);
        renderer.EnqueuePass(_postProcessPass);
    }

    public override void Create()
    {
        _postProcessPass = new ComicRenderPass(_applyToSceneView, _shader);
    }
}
