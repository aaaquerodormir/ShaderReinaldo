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
        // TAGS CRUCIAIS PARA URP
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        LOD 100
        Cull Off // Renderiza os dois lados

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Inclui a biblioteca Core do URP
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

            // Declaracao de variaveis no padrao URP (CBUFFER para otimizacao)
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float _Cutoff;
                float _EdgeSize;
                float4 _EdgeColor;
            CBUFFER_END

            // Texturas sao declaradas fora do CBUFFER
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            Varyings vert(Attributes input)
            {
                Varyings output;
                // Converte posicao do objeto para Clip Space (Padrao URP)
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 1. Amostra a cor base
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                
                // 2. Amostra o ruido
                half noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, input.uv).r;

                // 3. Logica de Clip (Erosao)
                clip(noise - _Cutoff);

                // 4. Logica da Borda
                // Se o ruido for menor que o corte + tamanho da borda, pinta com a cor da borda
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