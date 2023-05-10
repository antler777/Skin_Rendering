Shader "URP/SSSSkin"
{
    Properties
    {
        _BaseMap("BaseMap", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        _NormalMap("Normal Map",2D) = "bump"{}
        _LutMap("LutMap", 2D) = "white" {}
        
        _SpecularMap("SpeculaMap", 2D) = "white" {}
        _Specular("Specular",Range(0.0,1.0)) = 0.5
        
        _Occlusion("Occlusion",Range(0.0,1.0)) = 0.0
        _AOMap("AO",2D) = "black"{}
        
        _RoughnessMap("Roughness", 2D) = "gray" {}
        _RoughnessmaskMap("Roughness mask", 2D) = "black" {}
        [Space][Header(General Roughness)][Space]
        _Lobe0Roughness ("GeneralLobe0Roughness",Range(0.0,1.0)) = 0.0
        _Lobe1Roughness ("GeneralLobe1Roughness",Range(0.0,1.0)) = 1.0
        [Space][Header(Nose Roughness)][Space]
        _NoseLobe0Roughness ("NoseLobe0Roughness",Range(0.0,1.0)) = 0.0
        _NoseLobe1Roughness ("NoseLobe1Roughness",Range(0.0,1.0)) = 1.0
        [Space][Header(Forehead Roughness)][Space]
        _foreheadLobe0Roughness ("foreheadLobe0Roughness",Range(0.0,1.0)) = 0.0
        _foreheadLobe1Roughness ("foreheadLobe1Roughness",Range(0.0,1.0)) = 1.0
        [Space][Header(Mouse Roughness)][Space]
        _mouseLobe0Roughness ("mouseLobe0Roughness",Range(0.0,1.0)) = 0.0
        _mouseLobe1Roughness ("mouseLobe1Roughness",Range(0.0,1.0)) = 1.0
        

        _DetailNormalMap("Detail Normal Map",2D) = "bump"{}
        _DetailBlurNormalMap("Detail Blur Normal Map",2D) = "bump"{}
        _DetailMaskMap("DetailMask",2D) = "black"{}
        
        _DetailTilling("DetailTilling",float) = 10
        _DetailNormalStrength("Detail Normal Strength",float) = 0.4
        
        _ClearCoatMaskMap("Clear Coat Mask",2D) = "black"{}
        _ClearCoat ("ClearCoat",Range(0.0,1.0)) = 0.0
        _ClearCoatRoughness ("ClearCoat Roughness",Range(0.0,1.0)) = 0.0
        _EnvRotation("EnvRotation",Range(0.0,360.0)) = 0.0
        
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        [Toggle(_SSS_OFF)] _SSS_OFF("SSS OFF",Float) = 0.0
        [Toggle(_SH_OFF)] _SH_OFF("SH OFF",Float) = 0.0
        [Toggle(_SPECULAR_OFF)] _SPECULAR_OFF("SPECULAR OFF",Float) = 0.0
        [Toggle(_DIFFUSE_OFF)] _DIFFUSE_OFF("DIFFUSE OFF",Float) = 0.0
        [Toggle(_IBL_OFF)] _IBL_OFF("IBL OFF",Float) = 0.0
    }

    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"}
        LOD 300

        // ------------------------------------------------------------------
        //  Forward pass. Shades all light in a single pass. GI + emission + Fog
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _SSS_OFF
            #pragma shader_feature_local_fragment _DIFFUSE_OFF
            #pragma shader_feature_local_fragment _SPECULAR_OFF
            #pragma shader_feature_local_fragment _SH_OFF
            #pragma shader_feature_local_fragment _IBL_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "SkinLighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                half3 normalWS : TEXCOORD2;
                half4 tangentWS : TEXCOORD3;    // xyz: tangent, w: sign
                float4 shadowCoord : TEXCOORD4;
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
   
            TEXTURE2D(_LutMap);    SAMPLER(sampler_LutMap);
            TEXTURE2D(_SpecularMap);    SAMPLER(sampler_SpecularMap);
            TEXTURE2D(_RoughnessMap);    SAMPLER(sampler_RoughnessMap);
            
            TEXTURE2D(_RoughnessmaskMap);    SAMPLER(sampler_RoughnessmaskMap);
         
            TEXTURE2D(_NormalMap);    SAMPLER(sampler_NormalMap);
            TEXTURE2D(_DetailNormalMap);    SAMPLER(sampler_DetailNormalMap);
            TEXTURE2D(_AOMap);    SAMPLER(sampler_AOMap);
     
            TEXTURE2D(_DetailBlurNormalMap);    SAMPLER(sampler_DetailBlurNormalMap);
            TEXTURE2D(_DetailMaskMap);       SAMPLER(sampler_DetailMaskMap);
            TEXTURE2D(_ClearCoatMaskMap);    SAMPLER(sampler_ClearCoatMaskMap);


     
            
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _Specular;
            half _Lobe0Roughness;
            half _Lobe1Roughness;
            half _NoseLobe0Roughness;
            half _NoseLobe1Roughness ;
            half _foreheadLobe0Roughness ;
            half _foreheadLobe1Roughness;
            half _mouseLobe0Roughness;
            half _mouseLobe1Roughness;
            half _Occlusion;
            half _DetailTilling;
            half _DetailNormalStrength;
            half _ClearCoat;
            half _ClearCoatRoughness;
            half _Cutoff;
            half _EnvRotation;
            CBUFFER_END

            // Used in Standard (Physically Based) shader
            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.uv = input.texcoord;
                output.normalWS = normalInput.normalWS;
                real sign = input.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                output.tangentWS = tangentWS;
                //half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
                output.positionWS = vertexInput.positionWS;
                output.shadowCoord = GetShadowCoord(vertexInput);
                output.positionCS = vertexInput.positionCS;

                return output;
            }

            half4 LitPassFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                //---------------input data-----------------
                float2 UV = input.uv;
                float3 WorldPos = input.positionWS;
                half3 ViewDir = GetWorldSpaceNormalizeViewDir(WorldPos);
                half3 WorldNormal = normalize(input.normalWS);
                half3 WorldTangent = normalize(input.tangentWS.xyz);
                half3 WorldBinormal = normalize(cross(WorldNormal,WorldTangent) * input.tangentWS.w);
                half3x3 TBN = half3x3(WorldTangent,WorldBinormal,WorldNormal);

                float4 ShadowCoord = input.shadowCoord;
                float2 ScreenUV = GetNormalizedScreenSpaceUV(input.positionCS);
                half4 ShadowMask = float4(1.0,1.0,1.0,1.0);
                //------------------material----------------
                half4 BaseColorAlpha = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,UV) * _BaseColor;
                half3 BaseColor = BaseColorAlpha.rgb;
                half SpecularColor = SAMPLE_TEXTURE2D(_SpecularMap,sampler_SpecularMap,UV).r*_Specular;

                half BaseAlpha = BaseColorAlpha.a;
                half3 Specualr = lerp(SpecularColor*0.05f,BaseColor,0);
                #if defined(_ALPHATEST_ON)
                    clip(BaseAlpha - _Cutoff);
                #endif
              
                float Roughness = SAMPLE_TEXTURE2D(_RoughnessMap,sampler_RoughnessMap,UV).r ;
                float3 RoughnessMask = SAMPLE_TEXTURE2D(_RoughnessmaskMap,sampler_RoughnessmaskMap,UV);
                float nose = RoughnessMask.r;
                float forehead = RoughnessMask.g;
                float mouse = RoughnessMask.b;
                
                float other = 1-nose-forehead-mouse;
                
                half Roughness0 = max(Roughness*(_Lobe0Roughness*other+nose*_NoseLobe0Roughness+forehead*_foreheadLobe0Roughness+mouse*_mouseLobe0Roughness),0.01);
                half Roughness1 = 0.85;
                half Lobemix = max(Roughness*(_Lobe1Roughness*other+nose*_NoseLobe1Roughness+forehead*_foreheadLobe1Roughness+mouse*_mouseLobe1Roughness),0.01);

                half3 NormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,UV),1);
                half3 DetailNormalTS=UnpackNormalScale(SAMPLE_TEXTURE2D(_DetailNormalMap,sampler_DetailNormalMap,UV*_DetailTilling),_DetailNormalStrength);
                half3 DetailNormalblurTS=UnpackNormalScale(SAMPLE_TEXTURE2D(_DetailBlurNormalMap,sampler_DetailBlurNormalMap,UV*_DetailTilling),_DetailNormalStrength);

                half ClearCoat=mouse;
                ClearCoat *=_ClearCoat*BaseColor; 
                half Curvature =0;
                GetCurvature_float(WorldNormal,WorldPos,Curvature);
                half DetailMask = SAMPLE_TEXTURE2D(_DetailMaskMap,sampler_DetailMaskMap,UV).r ;
                
                half3 Normal = lerp(NormalTS,DetailNormalTS,1-Curvature);
                half3 Normal_blur = lerp(NormalTS,DetailNormalblurTS,1-Curvature);
                Normal_blur = normalize(mul(Normal_blur,TBN));
                Normal = normalize(mul(Normal,TBN));
                
                WorldNormal = normalize(mul(NormalTS,TBN));

                half3 ClearCoatNormal = (0,0,1);
                ClearCoatNormal = normalize(mul(ClearCoatNormal,TBN));
                
               // half AOmap = SAMPLE_TEXTURE2D(_DetailMaskMap,sampler_DetailMaskMap,UV).r ;
                half SSAO=SAMPLE_TEXTURE2D(_AOMap,sampler_AOMap,UV).r ;;
                //GetSSAO_float(ScreenUV,SSAO);

                half AO = lerp(1.0,SSAO,_Occlusion);
                //--------------------BRDF-----------------
 
                Roughness = max(Roughness,0.001f);


                //-----------direct lighting------------
                half3 DirectLighting = half3(0,0,0);
                DirectLighting_float(BaseColor,Specualr,Roughness0,Roughness1,Lobemix,WorldPos,Normal,Normal_blur,ViewDir,
                    _LutMap,sampler_LutMap,Curvature,ClearCoat,_ClearCoatRoughness,ClearCoatNormal,DirectLighting);
                //-----------indirect lighting------------
                half3 IndirectLighting = half3(0,0,0);
                 IndirectLighting_float(BaseColor,Specualr,Roughness0,Roughness1,Lobemix,WorldPos,WorldNormal,
                     ViewDir,AO,_EnvRotation,ClearCoat,_ClearCoatRoughness,ClearCoatNormal,IndirectLighting);
                half4 color = half4(DirectLighting + IndirectLighting,1.0f);

                return color;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // -------------------------------------
            // Universal Pipeline keywords

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }

    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
