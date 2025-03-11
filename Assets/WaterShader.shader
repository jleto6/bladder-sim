Shader "Custom/WaterShader"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0, 0.3, 0.8, 1) // Water color
        _Smoothness ("Smoothness", Range(0,1)) = 0.9
        _WaveStrength ("Wave Strength", Range(0, 0.1)) = 0.02
        _WaveSpeed ("Wave Speed", Range(0,5)) = 1.0
        _DepthColor ("Depth Color", Color) = (0, 0, 0.3, 1)
        _DepthFactor ("Depth Factor", Range(0,5)) = 1.5
        _Refraction ("Refraction Amount", Range(0, 0.1)) = 0.02
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

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
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _CameraDepthTexture;
            half4 _BaseColor;
            half4 _DepthColor;
            float _DepthFactor;
            float _WaveStrength;
            float _WaveSpeed;
            float _Refraction;
            float _Smoothness;

            v2f vert (appdata_t v)
            {
                v2f o;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                v.vertex.y += sin(_Time.y * _WaveSpeed + v.vertex.x) * _WaveStrength;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                float depthFactor = saturate(depth * _DepthFactor);
                half4 color = lerp(_BaseColor, _DepthColor, depthFactor);

                return color;
            }
            ENDHLSL
        }
    }
}
