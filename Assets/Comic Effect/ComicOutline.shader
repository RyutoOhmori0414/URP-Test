Shader "Custom/ComicOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineRange("Outline", Float) = 1
        _OutlineCol ("OutlineCol", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags
            { "LightMode" = "ToonOutline" }
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Library/ComicOutlineInput.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float fogFactor : TEXCOORD0;
            };

            v2f vert (appdata i)
            {
                v2f o;

                o.vertex = TransformObjectToHClip(i.vertex.xyz + i.normal * _OutlineRange);
                o.fogFactor = ComputeFogFactor(o.vertex.z);

                return o;
            }

            half4 frag (v2f i) : SV_TARGET
            {
                return half4(MixFog(_OutlineCol, i.fogFactor), _OutlineCol.a);
            }

            ENDHLSL
        }

        Pass
        {
            Tags
            { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Library/ComicOutlineInput.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float fogFactor : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                
                col.rgb = MixFog(col.rgb, i.fogFactor);

                return col;
            }
            ENDHLSL
        }
    }
}
