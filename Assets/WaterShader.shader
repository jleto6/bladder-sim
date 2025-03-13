Shader "Custom/WaterShader"
{
    Properties
    {
        _ShallowColor ("Shallow Color", Color) = (0.325, 0.807, 0.971, 0.9)
        _DeepColor ("Deep Color", Color) = (0.086, 0.407, 1, 0.9)
        _DepthScale ("Depth Scale", Range(0, 10)) = 1.5
        _DepthPower ("Depth Power", Range(0, 5)) = 1.0
        
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _BumpStrength ("Bump Strength", Range(0, 2)) = 0.5
        
        _Glossiness ("Smoothness", Range(0, 1)) = 0.9
        _Metallic ("Metallic", Range(0, 1)) = 0
        
        _WaveFrequency ("Wave Frequency", Range(0, 10)) = 1
        _WaveScale ("Wave Scale", Range(0, 1)) = 0.1
        _WaveSpeed ("Wave Speed", Range(0, 10)) = 1
        
        _ScrollSpeed ("Scroll Speed", Range(0, 5)) = 0.5
        
        _FoamWidth ("Foam Width", Range(0, 10)) = 1.0
        _FoamNoise ("Foam Noise", 2D) = "white" {}
        _DepthFoam ("Depth Foam", Range(0, 2)) = 1.0
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
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
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
                float4 screenPos    : TEXCOORD5;
                float  fogFactor    : TEXCOORD6;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _ShallowColor;
                float4 _DeepColor;
                float _DepthScale;
                float _DepthPower;
                float _BumpStrength;
                float _Glossiness;
                float _Metallic;
                float _WaveFrequency;
                float _WaveScale;
                float _WaveSpeed;
                float _ScrollSpeed;
                float _FoamWidth;
                float _DepthFoam;
                float4 _NormalMap_ST;
                float4 _FoamNoise_ST;
            CBUFFER_END
            
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            TEXTURE2D(_FoamNoise);
            SAMPLER(sampler_FoamNoise);
            
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
                output.screenPos = ComputeScreenPos(output.positionCS);
                
                // Calculate normal, tangent and bitangent
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInputs.normalWS;
                output.tangentWS = normalInputs.tangentWS;
                output.bitangentWS = normalInputs.bitangentWS;
                
                // Scrolling UVs for water movement
                output.uv = input.uv + _Time.y * float2(_ScrollSpeed, _ScrollSpeed);
                
                // Calculate fog factor
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                
                return output;
            }
            
            float4 frag(Varyings input) : SV_Target
            {
                // Sample normal map with scrolling UVs
                float2 normalUV = TRANSFORM_TEX(input.uv, _NormalMap);
                float3 normalMap = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normalUV));
                normalMap.xy *= _BumpStrength;
                
                // Transform normal from tangent to world space
                float3x3 tangentToWorld = float3x3(
                    input.tangentWS,
                    input.bitangentWS,
                    input.normalWS
                );
                float3 normalWS = mul(normalMap, tangentToWorld);
                
                // Sample foam noise texture
                float2 foamUV = TRANSFORM_TEX(input.uv, _FoamNoise);
                float foamNoise = SAMPLE_TEXTURE2D(_FoamNoise, sampler_FoamNoise, foamUV).r;
                
                // Calculate screen UV for depth
                float2 screenUV = input.screenPos.xy / input.screenPos.w;
                
                // Get scene depth and calculate linear eye depth
                float sceneDepth = SampleSceneDepth(screenUV);
                float linearEyeDepth = LinearEyeDepth(sceneDepth, _ZBufferParams);
                float linearEyeDepthInput = LinearEyeDepth(input.positionCS.z, _ZBufferParams);
                
                // Calculate water depth
                float waterDepth = linearEyeDepth - linearEyeDepthInput;
                float depthFade = saturate(exp(-waterDepth * _DepthScale));
                
                // Lerp between deep and shallow water colors based on depth
                float4 waterColor = lerp(_DeepColor, _ShallowColor, pow(depthFade, _DepthPower));
                
                // Calculate foam based on depth
                float edge = 1.0 - saturate(waterDepth / _FoamWidth);
                float foam = saturate(edge + foamNoise * edge * _DepthFoam);
                
                // Add foam to water color
                waterColor.rgb = lerp(waterColor.rgb, float3(1, 1, 1), foam);
                
                // Lighting calculations
                InputData lightingInput = (InputData)0;
                lightingInput.normalWS = normalize(normalWS);
                lightingInput.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                lightingInput.positionWS = input.positionWS;
                lightingInput.shadowCoord = float4(0, 0, 0, 0); // Not handling shadows in this simplified version
                lightingInput.fogCoord = input.fogFactor;
                
                SurfaceData surfaceInput = (SurfaceData)0;
                surfaceInput.albedo = waterColor.rgb;
                surfaceInput.alpha = waterColor.a;
                surfaceInput.metallic = _Metallic;
                surfaceInput.smoothness = _Glossiness;
                
                // Apply URP lighting
                float4 finalColor = UniversalFragmentPBR(lightingInput, surfaceInput);
                
                // Improved alpha calculation to prevent excessive transparency
                finalColor.a = lerp(waterColor.a, 1.0, foam) * saturate(1.0 - exp(-waterDepth * 0.5));
                
                return finalColor;
            }
            ENDHLSL
        }
        
        // Shadow caster pass (simplified to avoid include file dependency)
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
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            // Include needed constant buffers and utility functions
            CBUFFER_START(UnityPerMaterial)
                float _WaveFrequency;
                float _WaveScale;
                float _WaveSpeed;
            CBUFFER_END
            
            // Shadow pass vertex and fragment structure
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
            
            // Renamed to avoid conflict with built-in function
            float3 CustomApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirectionWS)
            {
                float invNdotL = 1.0 - saturate(dot(normalWS, lightDirectionWS));
                float scale = invNdotL * 0.01;
                
                // Apply normal offset bias
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
                
                // Apply shadow bias (using our custom function)
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