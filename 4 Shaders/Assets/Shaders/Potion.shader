Shader "Custom/URP_Potion"
{
    Properties
    {
        [Header(Liquid Colors)]
        _ColorTop ("Top Color", Color) = (0.0, 1.0, 1.0, 1)
        _ColorBottom ("Bottom Color", Color) = (0.0, 0.5, 0.8, 1)
        
        [Header(Magic Rim Effect)]
        [HDR] _RimColor ("Rim Color (Fresnel)", Color) = (0.5, 1.0, 1.0, 1)
        _RimPower ("Rim Power", Range(0.5, 8.0)) = 3.0

        [Header(Movement)]
        _WobbleSpeed ("Wobble Speed", Range(0, 10)) = 2.0
        _WobbleAmount ("Wobble Amount", Range(0, 0.1)) = 0.02
    }
    SubShader
    {
        // Tags para Transparencia
        // Queue Transparent renderiza depois dos objetos opacos
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
        LOD 100
        
        // Ativa a transparencia padrao
        Blend SrcAlpha OneMinusSrcAlpha
        // Nao escreve no Z-Buffer (comum para liquidos internos)
        ZWrite Off 

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
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD3; // Direcao da camera para o Fresnel
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _ColorTop;
                float4 _ColorBottom;
                float4 _RimColor;
                float _RimPower;
                float _WobbleSpeed;
                float _WobbleAmount;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                float3 pos = input.positionOS.xyz;

                // 1. Movimento (Wobble)
                // Adicionamos um movimento nas ondas usando seno e cosseno
                float wobble = sin(_Time.y * _WobbleSpeed + pos.x * 5.0) * cos(_Time.y * _WobbleSpeed * 0.8 + pos.z * 5.0);
                
                // O movimento e mais forte no topo (uv.y perto de 1) e zero no fundo
                pos.y += wobble * _WobbleAmount * input.uv.y;

                output.positionCS = TransformObjectToHClip(pos);
                output.uv = input.uv;

                // 2. Dados para o Fresnel
                // Posicao do vertice no mundo
                float3 positionWS = TransformObjectToWorld(pos);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                // Calcula o vetor que aponta do objeto para a camera
                output.viewDirWS = GetWorldSpaceViewDir(positionWS);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 1. Gradiente Vertical
                // Mistura a cor do fundo e do topo baseado na altura UV
                half4 baseColor = lerp(_ColorBottom, _ColorTop, input.uv.y);

                // 2. Calculo do Fresnel (A Magica)
                float3 normal = normalize(input.normalWS);
                float3 viewDir = normalize(input.viewDirWS);
                
                // Produto Escalar: 1 se olha de frente, 0 se olha para a borda
                float NdotV = dot(normal, viewDir);
                
                // Invertemos para brilhar na borda e elevamos a potencia
                float rim = pow(1.0 - saturate(NdotV), _RimPower);

                // 3. Combinacao Final
                // Adiciona a cor da borda sobre a cor base
                half3 finalRGB = baseColor.rgb + (_RimColor.rgb * rim);
                
                // Garante que a borda seja visivel mesmo onde o liquido seria transparente
                half finalAlpha = max(baseColor.a, rim * _RimColor.a);

                return half4(finalRGB, finalAlpha);
            }
            ENDHLSL
        }
    }
}