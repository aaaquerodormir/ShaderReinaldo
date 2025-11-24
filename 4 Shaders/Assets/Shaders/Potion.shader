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
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
        LOD 100
        
        Blend SrcAlpha OneMinusSrcAlpha
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
                float3 viewDirWS : TEXCOORD3;
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

                float wobble = sin(_Time.y * _WobbleSpeed + pos.x * 5.0) * cos(_Time.y * _WobbleSpeed * 0.8 + pos.z * 5.0);
                
                pos.y += wobble * _WobbleAmount * input.uv.y;

                output.positionCS = TransformObjectToHClip(pos);
                output.uv = input.uv;

                float3 positionWS = TransformObjectToWorld(pos);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                output.viewDirWS = GetWorldSpaceViewDir(positionWS);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 baseColor = lerp(_ColorBottom, _ColorTop, input.uv.y);

                float3 normal = normalize(input.normalWS);
                float3 viewDir = normalize(input.viewDirWS);
                
                float NdotV = dot(normal, viewDir);
                
                float rim = pow(1.0 - saturate(NdotV), _RimPower);

                half3 finalRGB = baseColor.rgb + (_RimColor.rgb * rim);
                
                half finalAlpha = max(baseColor.a, rim * _RimColor.a);

                return half4(finalRGB, finalAlpha);
            }
            ENDHLSL
        }
    }
}