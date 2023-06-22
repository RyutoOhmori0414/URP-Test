using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ComicRenderPass : ScriptableRenderPass
{
    private const string RenderPassName = nameof(ComicRenderPass);
    private const string ProfilingSamplerName = "SrcToDest";

    private bool _applyToSceneView;
    private readonly int _mainTexPropertyId = Shader.PropertyToID("_MainTex");
    private readonly Material _material;
    private readonly ProfilingSampler _profilingSampler;
    private readonly int _blurRangePropertyId = Shader.PropertyToID("_BlurRange");
    private readonly int _blurDirectionPropertyId = Shader.PropertyToID("_BlurDir");

    private RenderTargetHandle _afterPostProcessTexture;
    private RenderTargetIdentifier _cameraColorTarget;
    private RenderTargetHandle _tempRenderTargetHandle;
    private ComicVolume _volume;

    public ComicRenderPass(bool applyToSceneView, Shader shader)
    {
        if (!shader)
        {
            return;
        }

        _applyToSceneView = applyToSceneView;
        _profilingSampler = new ProfilingSampler(ProfilingSamplerName);
        _tempRenderTargetHandle.Init("_TempRT");

        _material = CoreUtils.CreateEngineMaterial(shader);
        _afterPostProcessTexture.Init("_AfterPostProcessTexture");
    }

    public void Setup(RenderTargetIdentifier cameraColorTarget, PostProcessTiming timing)
    {
        _cameraColorTarget = cameraColorTarget;
        renderPassEvent = GetRenderPassEvent(timing);
        var volumeStack = VolumeManager.instance.stack;
        _volume = volumeStack.GetComponent<ComicVolume>();
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (!_material || !renderingData.cameraData.postProcessEnabled ||
            (!_applyToSceneView && renderingData.cameraData.cameraType == CameraType.SceneView) ||
            !_volume.IsActive())
        {
            return;
        }

        var source = renderPassEvent == RenderPassEvent.AfterRendering && renderingData.cameraData.resolveFinalTarget
            ? _afterPostProcessTexture.Identifier()
            : _cameraColorTarget;

        var cmd = CommandBufferPool.Get(RenderPassName);
        cmd.Clear();

        var tempTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;
        tempTargetDescriptor.depthBufferBits = 0;
        cmd.GetTemporaryRT(_tempRenderTargetHandle.id, tempTargetDescriptor);

        using (new ProfilingScope(cmd, _profilingSampler))
        {
            _material.SetFloat(_blurRangePropertyId, _volume.BlurRange.value);
            _material.SetVector(_blurDirectionPropertyId, new Vector4(_volume.BlurDirection.value.x, _volume.BlurDirection.value.y));
            cmd.SetGlobalTexture(_mainTexPropertyId, source);

            Blit(cmd, source, _tempRenderTargetHandle.Identifier(), _material);
        }

        Blit(cmd, _tempRenderTargetHandle.Identifier(), source);

        cmd.ReleaseTemporaryRT(_tempRenderTargetHandle.id);

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
    private RenderPassEvent GetRenderPassEvent(PostProcessTiming postprocessTiming)
    {
        switch (postprocessTiming)
        {
            case PostProcessTiming.AfterOpaque:
                return RenderPassEvent.AfterRenderingSkybox;
            case PostProcessTiming.BeforePostProcess:
                return RenderPassEvent.BeforeRenderingPostProcessing;
            case PostProcessTiming.AfterPostProcess:
                return RenderPassEvent.AfterRendering;
            default:
                throw new System.ArgumentOutOfRangeException(nameof(postprocessTiming), postprocessTiming, null);
        }
    }
}
