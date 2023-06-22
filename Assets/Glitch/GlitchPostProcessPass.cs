using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public enum PostprocessTiming
{
    AfterOpaque,
    BeforePostprocess,
    AfterPostprocess
}

public class GlitchPostProcessPass : ScriptableRenderPass
{
    private const string RenderPassName = nameof(GlitchPostProcessPass);
    private const string ProfilingSamplerName = "SrcToDest";

    private readonly bool _applyToSceneView;
    private readonly int _mainTexPropertyId = Shader.PropertyToID("_MainTex");
    private readonly Material _material;
    private readonly ProfilingSampler _profilingSampler;
    private readonly int _lineColorId = Shader.PropertyToID("_LineColor");
    private readonly int _lineSpeedId = Shader.PropertyToID("_LineSpeed");
    private readonly int _lineSizeId = Shader.PropertyToID("_LineSize");
    private readonly int _colorGapId = Shader.PropertyToID("_ColorGap");
    private readonly int _frameRateId = Shader.PropertyToID("_FrameRate");
    private readonly int _frequencyId = Shader.PropertyToID("_Frequency");
    private readonly int _glitchScaleId = Shader.PropertyToID("_GlitchScale");

    private RenderTargetHandle _afterPostProcessTexture;
    private RenderTargetIdentifier _cameraColorTarget;
    private RenderTargetHandle _tempRenderTargetHandle;
    private GlitchVolume _volume;


    public GlitchPostProcessPass(bool applyToSceneView, Shader shader)
    {
        if (shader == null)
        {
            return;
        }

        _applyToSceneView = applyToSceneView;
        _profilingSampler = new ProfilingSampler(ProfilingSamplerName);
        _tempRenderTargetHandle.Init("_TempRT");

        _material = CoreUtils.CreateEngineMaterial(shader);
        _afterPostProcessTexture.Init("_AfterPostProcessTexture");
    }

    public void Setup(RenderTargetIdentifier cameraColorTarget, PostprocessTiming timing)
    {
        _cameraColorTarget = cameraColorTarget;
        renderPassEvent = GetRenderPassEvent(timing);
        var volumeStack = VolumeManager.instance.stack;
        _volume = volumeStack.GetComponent<GlitchVolume>();
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        Debug.Log(renderPassEvent);
        
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

        using (new UnityEngine.Rendering.ProfilingScope(cmd, _profilingSampler))
        {
            // Volume����TintColor���擾���Ĕ��f
            _material.SetColor(_lineColorId, _volume.LineColorParamator.value);
            _material.SetFloat(_lineSpeedId, _volume.LineSpeedParamator.value);
            _material.SetFloat(_lineSizeId, _volume.LineSizeParamator.value);
            _material.SetFloat(_colorGapId, _volume.ColorGapParamater.value);
            _material.SetFloat(_frameRateId, _volume.FrameRateParamater.value);
            _material.SetFloat(_frequencyId, _volume.FrequencyParamater.value);
            _material.SetFloat(_glitchScaleId, _volume.GlitchScaleParamater.value);
            cmd.SetGlobalTexture(_mainTexPropertyId, source);

            // ���̃e�N�X�`������ꎞ�I�ȃe�N�X�`���ɃG�t�F�N�g��K�p���`��
            Blit(cmd, source, _tempRenderTargetHandle.Identifier(), _material);
        }

        Blit(cmd, _tempRenderTargetHandle.Identifier(), source);

        cmd.ReleaseTemporaryRT(_tempRenderTargetHandle.id);

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    private static RenderPassEvent GetRenderPassEvent(PostprocessTiming postprocessTiming)
    {
        switch (postprocessTiming)
        {
            case PostprocessTiming.AfterOpaque:
                return RenderPassEvent.AfterRenderingSkybox;
            case PostprocessTiming.BeforePostprocess:
                return RenderPassEvent.BeforeRenderingPostProcessing;
            case PostprocessTiming.AfterPostprocess:
                return RenderPassEvent.AfterRendering;
            default:
                throw new ArgumentOutOfRangeException(nameof(postprocessTiming), postprocessTiming, null);
        }
    }
}
