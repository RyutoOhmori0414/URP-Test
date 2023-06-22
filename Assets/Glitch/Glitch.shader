Shader "Custom/Glitch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LineColor ("LineColor", Color) = (0,0,0,0)
        _LineSpeed("LineSpeed",Range(0,10)) = 5
        _LineSize("LineSize",Range(0,1)) = 0.01
        _ColorGap("ColorGap",Range(0,1.0)) = 0.01
        _FrameRate ("FrameRate", Range(0,30)) = 15
        _Frequency  ("Frequency", Range(0,1)) = 0.1
        _GlitchScale  ("GlitchScale", Range(1,10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        LOD 100

        Blend One OneMinusSrcAlpha

        Pass
        {
            Tags { "LightMode" = "Universal2D"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile USE_SHAPE_LIGHT_TYPE_0 __
            #pragma multi_compile USE_SHAPE_LIGHT_TYPE_1 __
            #pragma multi_compile USE_SHAPE_LIGHT_TYPE_2 __
            #pragma multi_compile USE_SHAPE_LIGHT_TYPE_3 __
            #pragma multi_compile _ DEBUG_DISPLAY
            #pragma multi_compile _ NONLIGHTING
           
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 line_uv : TEXCOORD1;
                float4 color : COLOR;
                float4 vertex : SV_POSITION;
                #ifndef NONLIGHTING
                half2 lightingUV : TEXCOORD2;
                #endif
                #if defined(DEBUG_DISPLAY)
                float3 vertexWS : TEXCOORD3;
                #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            #include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/LightingUtility.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            float4 _MainTex_ST;
            float4 _TextureSampleAdd;
            float4 _LineColor;
            float _LineSpeed;
            float _Linesize;
            float _ColorGap;
            float _FrameRate;
            float _Frequency;
            float _GlitchScale;

            #if USE_SHAPE_LIGHT_TYPE_0
            SHAPE_LIGHT(0)
            #endif

            #if USE_SHAPE_LIGHT_TYPE_1
            SHAPE_LIGHT(1)
            #endif

            #if USE_SHAPE_LIGHT_TYPE_2
            SHAPE_LIGHT(2)
            #endif

            #if USE_SHAPE_LIGHT_TYPE_3
            SHAPE_LIGHT(3)
            #endif

            float rand(float2 co)
            {
                return frac(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
            }

            float perlinNoise(float2 st)
            {
                float2 p = floor(st);
                float2 f = frac(st);
                float2 u = f * f * (3.0 - 2.0 * f);

                float v00 = rand(p + float2(0, 0));
                float v10 = rand(p + float2(1, 0));
                float v01 = rand(p + float2(0, 1));
                float v11 = rand(p + float2(1, 1));

                return lerp(lerp(dot(v00, f - float2(0, 0)), dot(v10, f - float2(1, 0)), u.x),
                            lerp(dot(v01, f - float2(0, 1)), dot(v11, f - float2(1, 1)), u.x),
                            u.y) + 0.5f;
            }

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);

                #if defined(DEBUG_DISPLAY)
                o.vertexWS = TranformObjectToWorld(v.vertex.xyz);
                #endif

                o.color = v.color;
                o.uv = v.uv;
                o.line_uv = (v.uv - _Time.z) * _LineSpeed;

                #ifndef NONLIGHTING
                o.lightingUV = half2(ComputeScreenPos(o.vertex / o.vertex.w).xy);
                #endif
                return o;
            }

            #include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/CombinedShapeLightShared.hlsl"

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                //RGBをずらす
                float2 ra = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + _ColorGap * perlinNoise(_Time.z)).ra + _TextureSampleAdd.ra;
                float2 ba = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv - _ColorGap * perlinNoise(_Time.z)).ba + _TextureSampleAdd.ba;
                float2 ga = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).ga + _TextureSampleAdd.ga;
                float4 shiftColor = float4(ra.x, ga.x, ba.x, (ra.y+ ga.y + ba.y) / 3);
                //fracでv座標に15掛けた値の小数点以下の値でLineの太さを決めている
                float interpolation = step(frac(i.line_uv.y * 15), _Linesize);
                //線をlerpで実装している
                float4 noiseLineColor = lerp(shiftColor, _LineColor, interpolation);
                float posterize = floor(frac(perlinNoise(frac(_Time)) * 10) / (1 / _FrameRate)) * (1 / _FrameRate);
                // -1 < random < 1
                float noiseY = 2.0 * rand(posterize) - 0.5;
                // グリッチラインの太さv方向にランダムな値にしている
                float glitchLine1 = step(uv.y - noiseY, rand(uv));
                float glitchLine2 = step(uv.y - noiseY, 0);
                float glitch = saturate(glitchLine1 - glitchLine2);
                //X方向のノイズ計算 -0.1 < random < 1.0
                float noiseX = (2.0 * rand(posterize) - 0.5) * 0.1;
                float frequency = step(abs(noiseX), _Frequency);
                noiseX *= frequency;
                // グリッチを適用
                uv.x = lerp(uv.x, uv.x + noiseX * _GlitchScale, glitch);
                float4 noiseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv) + _TextureSampleAdd;
                float4 finalColor = noiseLineColor * noiseColor;
                #ifndef NONLIGHTING
                float4 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv);

                SurfaceData2D surfaceData;
                InputData2D inputData;

                InitializeSurfaceData(finalColor.rgb, finalColor.a, mask, surfaceData);
                InitializeInputData(i.uv, i.lightingUV, inputData);

                finalColor = CombinedShapeLightShared(surfaceData, inputData);
                #endif
                finalColor.rgb *= finalColor.a;
                return finalColor;
            }
            ENDHLSL
        }

        pass
        {
            Tags{ "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

           
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 line_uv : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 line_uv : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            float4 _TextureSampleAdd;
            float4 _LineColor;
            float _LineSpeed;
            float _Linesize;
            float _ColorGap;
            float _FrameRate;
            float _Frequency;
            float _GlitchScale;

            float rand(float2 co)
            {
                return frac(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
            }

            float perlinNoise(float2 st)
            {
                float2 p = floor(st);
                float2 f = frac(st);
                float2 u = f * f * (3.0 - 2.0 * f);

                float v00 = rand(p + float2(0, 0));
                float v10 = rand(p + float2(1, 0));
                float v01 = rand(p + float2(0, 1));
                float v11 = rand(p + float2(1, 1));

                return lerp(lerp(dot(v00, f - float2(0, 0)), dot(v10, f - float2(1, 0)), u.x),
                            lerp(dot(v01, f - float2(0, 1)), dot(v11, f - float2(1, 1)), u.x),
                            u.y) + 0.5f;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.line_uv = v.line_uv - _Time.z * _LineSpeed;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                //RGB�����炷
                float2 ra = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + _ColorGap * perlinNoise(_Time.z)).ra + _TextureSampleAdd.ra;
                float2 ba = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv - _ColorGap * perlinNoise(_Time.z)).ba + _TextureSampleAdd.ba;
                float2 ga = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).ga + _TextureSampleAdd.ga;
                float4 shiftColor = float4(ra.x, ga.x, ba.x, (ra.y+ ga.y + ba.y) / 3);
                //�m�Y�����C���̕⊮�l�̌v�Z
                float interpolation = step(frac(i.line_uv.y * 15), _Linesize);
                //�m�Y�����C�����܂ރs�N�Z���J���[
                float4 noiseLineColor = lerp(shiftColor, _LineColor, interpolation);
                float posterize = floor(frac(perlinNoise(frac(_Time)) * 10) / (1 / _FrameRate)) * (1 / _FrameRate);
                //uv.y�����̃m�C�Y�v�Z -1 < random < 1
                float noiseY = 2.0 * rand(posterize) - 0.5;
                //�O���b�`�̍����̕⊮�l�v�Z �x�̍����ɏo�����邩�͎��ԂŃ����_��
                float glitchLine1 = step(uv.y - noiseY, rand(uv));
                float glitchLine2 = step(uv.y - noiseY, 0);
                float glitch = saturate(glitchLine1 - glitchLine2);
                //uv.x�����̃m�C�Y�v�Z -0.1 < random < 1.0
                float noiseX = (2.0 * rand(posterize) - 0.5) * 0.1;
                float frequency = step(abs(noiseX), _Frequency);
                noiseX *= frequency;
                //�O���b�`�K�p
                uv.x = lerp(uv.x, uv.x + noiseX * _GlitchScale, glitch);
                float4 noiseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv) + _TextureSampleAdd;
                float4 finalColor = noiseLineColor * noiseColor;

                finalColor.rgb *= finalColor.a;
                return finalColor;
            }
            ENDHLSL

        }
    }
}
