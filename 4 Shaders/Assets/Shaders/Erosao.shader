Shader "Custom/URP_Erosao"
{
    Properties
    {
        _MainTex ("Albedo Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _Cutoff ("Cutoff", Range(0, 1)) = 0.0
        _EdgeSize ("Edge Size", Range(0.0, 0.5)) = 0.1
        _EdgeColor ("Edge Color", Color) = (1,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        LOD 100
        Cull Off

        Pass
        {
            Name "ForwardLit"
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
                float _EdgeSize;
                float4 _EdgeColor;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

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
                 
                half noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, input.uv).r;

                clip(noise - _Cutoff);

                if (noise < _Cutoff + _EdgeSize)
                {
                    return _EdgeColor;
                }

                return col;
            }
            ENDHLSL
        }
    }
}