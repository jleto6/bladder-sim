Shader "Custom/MetaballEffect"
{
    Properties
    {
        _Color ("Water Color", Color) = (0, 0.5, 1, 1)
        _Threshold ("Threshold", Range(0, 1)) = 0.3
        _Smoothness ("Smoothness", Range(0, 0.2)) = 0.08
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float _Threshold;
            float _Smoothness;
            half4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float dist = length(i.uv - float2(0.5, 0.5));
                float alpha = smoothstep(_Threshold, _Threshold + _Smoothness, 1.0 - dist);

                return half4(_Color.rgb, alpha);
            }
            ENDHLSL
        }
    }
}
