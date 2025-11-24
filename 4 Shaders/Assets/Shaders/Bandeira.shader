Shader "Custom/BandeiraURP"
{
    Properties
    {
        [Header(Texturas)]
        _MainTex ("Textura da Bandeira", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}

        [Header(Configuracao da Onda)]
        _Speed ("Velocidade", Range(0, 20)) = 10.0
        _Amount ("Intensidade da Onda", Range(0, 1)) = 0.2
        _Chaos ("Fator Caos", Range(1, 5)) = 3.0
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
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float _Speed;
                float _Amount;
                float _Chaos;
            CBUFFER_END

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);    SAMPLER(sampler_BumpMap);

            Varyings vert(Attributes input)
            {
                Varyings output;

                float3 pos = input.positionOS.xyz;

                float wobbleX = sin(_Time.y * _Speed + pos.y * _Chaos);
                float wobbleZ = cos(_Time.y * _Speed * 0.8 + pos.y * _Chaos);
                

                float invertedUV = 1.0 - input.uv.y; 
                float heightFactor = invertedUV * invertedUV;

                pos.x += wobbleX * _Amount * heightFactor;
                pos.z += wobbleZ * _Amount * heightFactor;
                pos.y += sin(_Time.y * _Speed * 2.0) * (_Amount * 0.2) * heightFactor;

                output.positionCS = TransformObjectToHClip(pos);
                
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);

                half4 packedNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv);
                float3 normalMap = UnpackNormal(packedNormal);

                float3 lightDir = normalize(float3(1, 1, -1));
                
                float3 finalNormal = normalize(input.normalWS + normalMap);
                
                float NdotL = max(0.0, dot(finalNormal, lightDir));
                
                float3 lighting = NdotL + 0.4;

                return half4(albedo.rgb * lighting, albedo.a);
            }
            ENDHLSL
        }
    }
}