#ifndef CUSTOM_COMICOUTLINE_INPUT_INCLUDED
#define CUSTOM_COMICOUTLINE_INPUT_INCLUDED

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);

CBUFFER_START(UnityPerMaterial)

float4 _MainTex_ST;
float _OutlineRange;
float4 _OutlineCol;

CBUFFER_END

#endif