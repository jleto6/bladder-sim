Shader "Custom/SciFiWall"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.6, 0.6, 0.6, 1) // Default gray
        _PanelScale ("Panel Scale", Float) = 4.0
        _EdgeWearAmount ("Edge Wear", Range(0, 1)) = 0.3
        _Roughness ("Roughness", Range(0, 1)) = 0.5
        _Metallic ("Metallic", Range(0, 1)) = 0.3
        _WearColor ("Wear Color", Color) = (0.3, 0.3, 0.3, 1) // Darker for worn areas
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : NORMAL;
                float3 worldPos : TEXCOORD1;
            };

            float4 _BaseColor;
            float _PanelScale;
            float _EdgeWearAmount;
            float _Roughness;
            float _Metallic;
            float4 _WearColor;

            v2f vert (appdata_t v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * _PanelScale;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            float rand(float2 co)
            {
                return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
            }

            half4 frag (v2f i) : SV_Target
            {
                // Generate panel lines
                float2 grid = frac(i.uv);
                float edgeMask = step(0.02, min(grid.x, grid.y)); // Panel seams

                // Add random dirt and wear near edges
                float wearMask = rand(i.uv) * _EdgeWearAmount * (1.0 - edgeMask);
                half4 finalColor = lerp(_BaseColor, _WearColor, wearMask);

                // Metallic and roughness effect
                float metallicFactor = lerp(0.0, _Metallic, edgeMask);
                float roughnessFactor = lerp(1.0, _Roughness, edgeMask);

                return finalColor;
            }
            ENDHLSL
        }
    }
}
