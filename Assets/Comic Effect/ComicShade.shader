Shader "Custom/ComicShade"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HalftoneScale ("HalftoneScale", Range(0.1, 0.01)) = 0.1
        [HDR]_ShadeColor ("ShadeColor", Color) = (1, 0, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float fogFactor : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)

            float4 _MainTex_ST;
            float _HalftoneScale;
            float4 _ShadeColor;

            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 screenPos = i.screenPos.xy / i.screenPos.w;
                float aspect = _ScreenParams.x / _ScreenParams.y;
                float2 cellSize = float2(_HalftoneScale, _HalftoneScale * aspect);

                float2 cellCenter;
                cellCenter.x = floor(screenPos.x / cellSize.x) * cellSize.x + cellSize.x / 2;
                cellCenter.y = floor(screenPos.y / cellSize.y) * cellSize.y + cellSize.y / 2;

                float2 diff = screenPos - cellCenter;
                diff.x /= cellSize.x;
                diff.y /= cellSize.y;

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                Light light = GetMainLight();
                float threshold = 1 - dot(i.normal, light.direction);

                col *= lerp(1, _ShadeColor, step(length(diff), threshold));

                col.rgb = MixFog(col.rgb, i.fogFactor);

                return col;
            }
            ENDHLSL
        }
    }
}
