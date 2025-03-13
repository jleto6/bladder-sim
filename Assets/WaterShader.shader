Shader "Custom/SimplifiedURPWaterShader"
{
    Properties
    {
        _WaterColor ("Water Color", Color) = (0.325, 0.807, 0.971, 0.8)
        _WaveFrequency ("Wave Frequency", Range(0, 10)) = 1
        _WaveScale ("Wave Scale", Range(0, 1)) = 0.1
        _WaveSpeed ("Wave Speed", Range(0, 10)) = 1
        
        // Normal map for ripples
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _BumpStrength ("Ripple Strength", Range(0, 1)) = 0.5
        _RippleSpeed ("Ripple Speed", Range(0, 2)) = 0.5
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent" 
            "Queue" = "Transparent" 
            "RenderPipeline" = "UniversalPipeline" 
        }
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            // Target 2.0 for wider WebGL support
            #pragma target 2.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 tangentWS    : TEXCOORD2;
                float3 bitangentWS  : TEXCOORD3;
                float3 positionWS   : TEXCOORD4;
                float  fogFactor    : TEXCOORD5;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _WaterColor;
                float _WaveFrequency;
                float _WaveScale;
                float _WaveSpeed;
                float _BumpStrength;
                float _RippleSpeed;
                float4 _NormalMap_ST;
            CBUFFER_END
            
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                // Apply wave animation
                float time = _Time.y * _WaveSpeed;
                float waveValue = sin(input.positionOS.x * _WaveFrequency + time) * 
                                  sin(input.positionOS.z * _WaveFrequency + time);
                input.positionOS.y += waveValue * _WaveScale;
                
                // Calculate position
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                
                // Calculate normal, tangent and bitangent for normal mapping
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInputs.normalWS;
                output.tangentWS = normalInputs.tangentWS;
                output.bitangentWS = normalInputs.bitangentWS;
                
                // Pass UV coordinates
                output.uv = input.uv;
                
                // Calculate fog factor
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                
                return output;
            }
            
            float4 frag(Varyings input) : SV_Target
            {
                // Create ripple effect with two overlapping normal maps moving in different directions
                float2 rippleUV1 = TRANSFORM_TEX(input.uv, _NormalMap) + _Time.y * float2(_RippleSpeed, 0);
                float2 rippleUV2 = TRANSFORM_TEX(input.uv, _NormalMap) + _Time.y * float2(0, _RippleSpeed * 0.7);
                
                // Sample normal maps and blend them
                float3 normalMap1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, rippleUV1));
                float3 normalMap2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, rippleUV2));
                float3 blendedNormal = normalize(normalMap1 + normalMap2);
                blendedNormal.xy *= _BumpStrength;
                
                // Transform normal from tangent to world space
                float3x3 tangentToWorld = float3x3(
                    input.tangentWS,
                    input.bitangentWS,
                    input.normalWS
                );
                float3 normalWS = mul(blendedNormal, tangentToWorld);
                
                // Get main light
                Light mainLight = GetMainLight();
                float3 lightDir = mainLight.direction;
                float3 lightColor = mainLight.color;
                
                // Basic lighting calculation with normal mapping
                float ndotl = max(0.4, dot(normalize(normalWS), lightDir));
                float3 diffuse = _WaterColor.rgb * lightColor * ndotl;
                
                // Add subtle specular highlight for ripples
                float3 viewDir = normalize(GetWorldSpaceViewDir(input.positionWS));
                float3 halfDir = normalize(lightDir + viewDir);
                float spec = pow(max(0.0, dot(normalWS, halfDir)), 64);
                float3 specular = spec * lightColor * 0.2; // Subtle highlight
                
                // Final lighting with specular
                float3 finalRGB = diffuse + specular;
                
                // Apply fog
                finalRGB = MixFog(finalRGB, input.fogFactor);
                
                // Return final color with alpha from _WaterColor
                return float4(finalRGB, _WaterColor.a);
            }
            ENDHLSL
        }
        
        // Shadow caster pass
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            #pragma target 2.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                float _WaveFrequency;
                float _WaveScale;
                float _WaveSpeed;
            CBUFFER_END
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            float3 CustomApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirectionWS)
            {
                float invNdotL = 1.0 - saturate(dot(normalWS, lightDirectionWS));
                float scale = invNdotL * 0.01;
                
                positionWS = lightDirectionWS * 0.001 + positionWS;
                positionWS -= normalWS * scale;
                return positionWS;
            }
            
            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                // Apply wave displacement
                float time = _Time.y * _WaveSpeed;
                float waveValue = sin(input.positionOS.x * _WaveFrequency + time) * 
                                  sin(input.positionOS.z * _WaveFrequency + time);
                input.positionOS.y += waveValue * _WaveScale;
                
                // Get position in world space
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                // Apply shadow bias
                float3 lightDirectionWS = _MainLightPosition.xyz;
                positionWS = CustomApplyShadowBias(positionWS, normalWS, lightDirectionWS);
                
                // Transform to clip space
                output.positionCS = TransformWorldToHClip(positionWS);
                
                #if UNITY_REVERSED_Z
                    output.positionCS.z = min(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    output.positionCS.z = max(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif
                
                return output;
            }
            
            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
        
        // Depth-only pass
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            
            ZWrite On
            ColorMask 0
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
            #pragma target 2.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                float _WaveFrequency;
                float _WaveScale;
                float _WaveSpeed;
            CBUFFER_END
            
            struct Attributes
            {
                float4 position     : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                float time = _Time.y * _WaveSpeed;
                float waveValue = sin(input.position.x * _WaveFrequency + time) * 
                                sin(input.position.z * _WaveFrequency + time);
                input.position.y += waveValue * _WaveScale;
                
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
    }
}