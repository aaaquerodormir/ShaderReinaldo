Shader "Custom/URP_Tela"
{
    Properties
    {
        _MainTex ("Albedo Texture", 2D) = "white" {}
        
        [Header(TV Static Settings)]
        _Cutoff ("Signal Loss (Cutoff)", Range(0, 1.1)) = 0.0
        _StaticDensity ("Static Density", Range(0, 100)) = 50.0
        _ScanlineFreq ("Scanline Frequency", Range(0, 100)) = 20.0
        
        [Header(Edge Appearance)]
        _EdgeWidth ("Noise Edge Width", Range(0, 0.5)) = 0.1
        _EdgeColor ("Static Color", Color) = (0.8, 0.8, 0.8, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="AlphaTest" }
        LOD 100
        Cull Off

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float _Cutoff;
                float _StaticDensity;
                float _ScanlineFreq;
                float _EdgeWidth;
                float4 _EdgeColor;
            CBUFFER_END

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            float random(float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);

                float2 pixelUV = floor(input.uv * _StaticDensity) / _StaticDensity;
                float noise = random(pixelUV + _Time.y);

                float scanline = sin(input.uv.y * _ScanlineFreq + _Time.y * 5.0);

                scanline = (scanline + 1.0) * 0.5;

                float signalQuality = noise * scanline;

                clip(signalQuality - _Cutoff);

                if (signalQuality < _Cutoff + _EdgeWidth)
                {
                    return _EdgeColor * noise; 
                }

                return col;
            }
            ENDHLSL
        }
    }
}