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
        _EdgeColor ("Static Color", Color) = (0.8, 0.8, 0.8, 1) // Cinza claro/Branco
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

            // Funcao auxiliar para gerar ruido aleatorio matematico (TV Snow)
            // Nao precisa de textura de ruido externa
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

                // 1. Gerar o Ruido de TV (Static)
                // Usamos _Time.y para fazer o ruido mudar a cada frame (animado)
                // floor(uv * density) cria o efeito de "pixels quadrados" gigantes
                float2 pixelUV = floor(input.uv * _StaticDensity) / _StaticDensity;
                float noise = random(pixelUV + _Time.y);

                // 2. Gerar Scanlines (Linhas Horizontais)
                float scanline = sin(input.uv.y * _ScanlineFreq + _Time.y * 5.0);
                // Normaliza para ficar entre 0 e 1
                scanline = (scanline + 1.0) * 0.5;

                // 3. Combina Ruido e Linhas para criar a "Mascara de Sinal"
                float signalQuality = noise * scanline;

                // 4. Logica de Erosao (Perda de Sinal)
                // Se o sinal for menor que o Cutoff, o pixel desaparece
                clip(signalQuality - _Cutoff);

                // 5. Borda de Chiado
                // Antes de desaparecer completamente, o pixel vira ruido branco/cinza
                if (signalQuality < _Cutoff + _EdgeWidth)
                {
                    // A borda nao e uma cor solida, ela pisca baseada no ruido
                    return _EdgeColor * noise; 
                }

                return col;
            }
            ENDHLSL
        }
    }
}