Shader "Custom/Tessellation"
{
    Properties
    {
        [Header(Base Color)]
        [MainTexture]_MainTex ("Texture", 2D) = "white" {}
        [HDR][MainColor]_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        [Header(Bump Map)]
        [MainTexture]_NormalMap("NormalMap", 2D) = "white" {}
        [MainTexture]_HeightMap("HeightMap", 2D) = "white" {}
        _Height("Height", float) = 1
        _HeightForNormal("_HeightForNormal", float) = 1
        [Header(Tesselllation)]
        _MinDist("MinDistance", Float) = 0.0
        _MaxDist("MaxDistance", Float) = 1.0
        _TessStrength("Tessellation Strength", Float) = 1
        _MinEdge("Min Edge", Range(0, 0.5)) = 0.4
        [Header(Lighting)]
        _ReceiveShadowMappingPosOffset("ShadowMapping Offset", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderPipline" = "UniversalPipline"
            "RenderType" = "Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            HLSLPROGRAM

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct VSInput
            {
                float3 positionOS : POSITION;
                half3 normalOS : NORMAL;
                half4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct HsInput
            {
                float4 positionOS : POS;
                half3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                half4 tangentOS : TEXCOORD1;
            };

            struct HsControlPointOutput
            {
                float3 positionOS : POS;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD;
                float4 tangentOS : TEXCOORD3;
            };

            struct HsConstantOutput
            {
                float tessFactor[3] : SV_TessFactor;
                float insideTessFactor : SV_InsideTessFactor;
            };

            struct DsOutput
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightTS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                real3 tangentWS : TEXCOORD4;
                real3 bitangentWS : TEXCOORD5;
            };

            struct LightingData2
            {
                half3 normalWS;
                float3 positionWS;
                half3 viewDirectionWS;
                float4 shadowCoord;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            TEXTURE2D(_HeightMap);
            SAMPLER(sampler_HeightMap);

            //マテリアルの値に変更があった場合、CBufferの値に更新をかける
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _NormalMap_ST;
            float _Height;
            float _HeightForNormal;
            float _MinEdge;
            float _MinDist;
            float _MaxDist;
            float _TessStrength;
            float _ReceiveShadowMappingPosOffset;
            CBUFFER_END
            
            HsInput vert (VSInput input)
            {
                HsInput output;

                output.positionOS = float4(input.positionOS, 1);
                output.uv = input.uv;
                output.tangentOS = input.tangentOS;
                output.normalOS = input.normalOS;

                // vertexシェーダでは、ObjectSpaceのまま変換を行わずにそのまま返す
                return output;
            }

            [domain("tri")]
            [partitioning("integer")]
            [outputtopology("triangle_cw")]
            [patchconstantfunc("hullConst")]
            [outputcontrolpoints(3)]
            HsControlPointOutput hull (InputPatch<HsInput, 3> input, uint id : SV_OutputControlPointID)
            {
                HsControlPointOutput output;
                output.positionOS = input[id].positionOS.xyz;
                output.normalOS = input[id].normalOS;
                output.uv = input[id].uv;
                output.tangentOS = input[id].tangentOS;
                return output;
            }

            real TessellationFactor (float4 vertex, float minDist, float maxDist, float tess)
            {
                float3 vertexWS = TransformObjectToWorld(vertex.xyz);
                float dist = distance(vertexWS, GetCameraPositionWS());
                float f = clamp((maxDist - minDist) / (dist - minDist), 0.01, 70) * _TessStrength;
                return f;
            }

            HsConstantOutput hullConst (InputPatch<HsInput, 3> i)
            {
                HsConstantOutput o;

                float4 p0 = i[0].positionOS;
                float4 p1 = i[1].positionOS;
                float4 p2 = i[2].positionOS;

                float edge0 = TessellationFactor(p0, _MinDist, _MaxDist, _TessStrength);
                float edge1 = TessellationFactor(p1, _MinDist, _MaxDist, _TessStrength);
                float edge2 = TessellationFactor(p2, _MinDist, _MaxDist, _TessStrength);

                // ここでテッセレーション関数を調整する。
                o.tessFactor[0] = (edge1 + edge2) / 2;
                o.tessFactor[1] = (edge0 + edge2) / 2;
                o.tessFactor[2] = (edge0 + edge1) / 2;
                o.insideTessFactor = (edge0 + edge1 + edge2) / 3;

                return o;
            }

            float3 NormalTSfromHeight(float2 uv, float height)
            {
                float2 e = float2(1, 0) / 256;
                float L = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, float4(uv - e, 0, 0), 0).r;
                float R = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, float4(uv + e, 0, 0), 0).r;
                float D = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, float4(uv - e.yx, 0, 0), 0).r;
                float U = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, float4(uv + e.yx, 0, 0), 0).r;
                return normalize(float3(2 * (L - R) * height * _HeightForNormal, 2 * (U - D) * height * _HeightForNormal, 4));
            }

            [domain("tri")]
            DsOutput domain(
                HsConstantOutput hsConst,
                const OutputPatch<HsControlPointOutput, 3> input,
                float3 bary : SV_DomainLocation)
            {
                DsOutput output;

                float3 positionOS =
                    bary.x * input[0].positionOS + 
                    bary.y * input[1].positionOS +
                    bary.z * input[2].positionOS;

                float3 normalOS = normalize(
                    bary.x * input[0].normalOS +
                    bary.y * input[1].normalOS +
                    bary.z * input[2].normalOS
                );

                output.uv =
                    bary.x * input[0].uv +
                    bary.y * input[1].uv +
                    bary.z * input[2].uv;

                float4 tangentOS = normalize(
                    bary.x * input[0].tangentOS + 
                    bary.y * input[1].tangentOS +
                    bary.z * input[2].tangentOS
                );

                // displacement
                float2 st = abs(output.uv - 0.5);
                // 角に向けて変化を0にする
                float edge = 1 - smoothstep(_MinEdge, 0.5, max(st.x, st.y));
                float disp = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, float4(output.uv, 0, 0), 0).r * _Height * edge;

                positionOS.xyz += normalOS * disp;
                float3 normal2TS = NormalTSfromHeight(output.uv, _Height * edge);

                real sign = tangentOS.w * GetOddNegativeScale();
                float3 bitangentOS = cross(normalOS, tangentOS) * sign;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS);
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(normalOS, tangentOS);

                output.positionCS = TransformWorldToHClip(vertexInput.positionWS.xyz);
                output.positionWS = vertexInput.positionWS;

                Light mainLight = GetMainLight();

                float3 tangentWS = vertexNormalInput.tangentWS;
                float3x4 tangentMat = float3x4(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS, float3(0, 0, 0));

                float3 normal2WS = mul(transpose(tangentMat), normal2TS);
                float3 tangent2WS = normalize(tangentWS - dot(tangentWS, normal2WS) * normal2WS);
                float3 bitangent2WS = cross(normal2WS, tangent2WS);

                float3x4 tangent2Mat = float3x4(tangent2WS, bitangent2WS, normal2WS, float3(0, 0, 0));

                output.lightTS = mul(tangent2Mat, mainLight.direction);

                output.normalWS = normal2WS;

                return output;
            }

            LightingData2 InitalizeLighting(DsOutput input)
            {
                LightingData2 lightingData;
                lightingData.positionWS = input.positionWS;
                lightingData.viewDirectionWS = SafeNormalize(GetCameraPositionWS() - lightingData.positionWS);

                float3 normalmap = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv));

                float3 normal = (input.tangentWS * normalmap.x) + (input.bitangentWS * normalmap.y) + (input.normalWS * normalmap.z);

                lightingData.normalWS = normalize(input.normalWS);

                return lightingData;
            }

            half3 BaseColor(DsOutput input)
            {
                half4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                float3 normal = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv));
                float diff = saturate(dot(input.lightTS, normal));

                col *= diff;

                return col.xyz;
            }

            half3 ShadeMainLight(half3 col, LightingData2 lightingData)
            {
                Light mainLight = GetMainLight();

                float3 shadowTestPosWS = lightingData.positionWS + mainLight.direction * _ReceiveShadowMappingPosOffset;

                float4 shadowCoord = TransformWorldToShadowCoord(lightingData.positionWS);
                mainLight.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);

                col *= mainLight.color * mainLight.shadowAttenuation;

                return col;
            }

            float4 frag (DsOutput input) : SV_Target
            {
                LightingData2 lightingData = InitalizeLighting(input);
                half3 col = BaseColor(input);

                half3 shaded = ShadeMainLight(col, lightingData);
                return half4(col, 1);
            }

            ENDHLSL
        }
    }
}
