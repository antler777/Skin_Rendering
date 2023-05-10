#ifndef SKIN_LIGHTING_INCLUDE
#define SKIN_LIGHTING_INCLUDE
#include "LightingCommon.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


float3 SkinBRDF( float3 DiffuseColor, float3 SpecularColor, float Lobe0Roughness,float Lobe1Roughness,float LobeMix,
	float3 N, float3 N_blur, float3 V, float3 L,float3 LightColor,float Shadow,float DiffuseShadow,
	Texture2D SSSLUT, SamplerState sampler_SSSLUT, float Curvature,
	float ClearCoat,float ClearCoatRoughness,float3 ClearCoatNormal)
{
	float3 H = normalize(L + V);
	float NoH = saturate(dot(N,H));
	float NoV = saturate(abs(dot(N,V)) + 1e-5);
	float NoL_blur = dot(N_blur,L);
	float NoL = dot(N,L);
	float VoH = saturate(dot(V,H));
	
	float NoL_Warp = NoL*0.5+0.5;
	float NoLBlur_Warp = NoL_blur * 0.5 + 0.5;
	// float2 UV_LUT = float2(NoL_Warp,Curvature);
	
	float2 UV_R = float2(NoLBlur_Warp,Curvature);
	float2 UV_G = float2(lerp(NoLBlur_Warp,NoL_Warp,0.2),Curvature);
	float2 UV_B = float2(lerp(NoLBlur_Warp,NoL_Warp,0.6),Curvature);
	
	float3 NoL_R = SAMPLE_TEXTURE2D(SSSLUT,sampler_SSSLUT,UV_R).xyz;
	float3 NoL_G = SAMPLE_TEXTURE2D(SSSLUT,sampler_SSSLUT,UV_G).xyz; 
	float3 NoL_B = SAMPLE_TEXTURE2D(SSSLUT,sampler_SSSLUT,UV_B).xyz;
	float3 NoL_Diff = (NoL_R + NoL_G + NoL_B) / 3;
	
	float3 DiffIrRadiance = NoL_Diff * LightColor * DiffuseShadow * PI;
	#if defined(_SSS_OFF)
		DiffIrRadiance = saturate(NoL) * LightColor * DiffuseShadow * PI;
	#endif
	float3 DiffuseTerm = Diffuse_Lambert(DiffuseColor) * DiffIrRadiance;
	#if defined(_DIFFUSE_OFF)
		DiffuseTerm = half3(0,0,0);
	#endif
	// Generalized microfacet specular
	float NoL_spec = saturate(NoL);
	float3 SpecIrRadiance = NoL_spec * LightColor * Shadow * PI;
	float3 SpecularBRDF = DualSpecularGGX(Lobe0Roughness, Lobe1Roughness, LobeMix,SpecularColor,NoH,NoV,NoL_spec,VoH);
	float3 SpecularTerm = SpecularBRDF * SpecIrRadiance;
	#if defined(_SPECULAR_OFF)
		SpecularTerm = half3(0,0,0);
	#endif
	//ClearCoat
	float3 EnergyLoss = float3(0.0,0.0,0.0);
	float3 ClearCoatLighting = max(0.0,ClearCoatGGX(ClearCoat, ClearCoatRoughness, N,V,L,EnergyLoss));
	DiffuseTerm*= (1.0-EnergyLoss);
	SpecularTerm*=(1.0-EnergyLoss);
	
	float3 DirectLighting = DiffuseTerm + SpecularTerm+ClearCoatLighting;
	return DirectLighting;
}

void DirectLighting_float(float3 DiffuseColor, float3 SpecularColor, float Lobe0Roughness,float Lobe1Roughness,float LobeMix,
							float3 WorldPos, float3 N,float3 N_blur, float3 V,
							Texture2D SSSLUT,SamplerState sampler_SSSLUT,float Curvature,
							float ClearCoat,float ClearCoatRoughness,float3 ClearCoatNormal,
							out float3 DirectLighting)
{
	DirectLighting = half3(0,0,0);
	#ifndef SHADERGRAPH_PREVIEW
	#if defined(_MAIN_LIGHT_SHADOWS_SCREEN) && !defined(_SURFACE_TYPE_TRANSPARENT)
	float4 positionCS = TransformWorldToHClip(WorldPos);
    float4 ShadowCoord = ComputeScreenPos(positionCS);
	#else
    float4 ShadowCoord = TransformWorldToShadowCoord(WorldPos);
	#endif
	float4 ShadowMask = float4(1.0,1.0,1.0,1.0);
	//main Light
    half3 DirectLighting_MainLight = half3(0,0,0);
    {
        Light light = GetMainLight(ShadowCoord,WorldPos,ShadowMask);
        half3 L = light.direction;
        half3 LightColor = light.color;
        half Shadow = saturate(light.shadowAttenuation+0.2);
		half3 DiffuseShadow = lerp(half3(0.11,0.025,0.012),float3(1,1,1),Shadow);
        DirectLighting_MainLight = SkinBRDF(DiffuseColor,SpecularColor,Lobe0Roughness, Lobe1Roughness, LobeMix,N,N_blur,V,L,LightColor,Shadow,DiffuseShadow,SSSLUT, sampler_SSSLUT, Curvature,ClearCoat,ClearCoatRoughness,ClearCoatNormal);
    }
    //Addtional Light
    half3 DirectLighting_AddLight = half3(0,0,0);
    #ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for(uint lightIndex = 0; lightIndex < pixelLightCount ; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex,WorldPos,ShadowMask);
        half3 L = light.direction;
        half3 LightColor = light.color;
        half Shadow = saturate(light.shadowAttenuation+0.2) * light.distanceAttenuation;
    	half3 DiffuseShadow = lerp(half3(0.11,0.025,0.012),float3(1,1,1),Shadow); 
        DirectLighting_AddLight += SkinBRDF(DiffuseColor,SpecularColor,Lobe0Roughness, Lobe1Roughness, LobeMix,N,N_blur,V,L,LightColor,Shadow,DiffuseShadow,SSSLUT, sampler_SSSLUT, Curvature,ClearCoat,ClearCoatRoughness,ClearCoatNormal);
    }
    #endif

    DirectLighting = DirectLighting_MainLight + DirectLighting_AddLight;
	#endif
}

void IndirectLighting_float(float3 DiffuseColor, float3 SpecularColor, float Lobe0Roughness,float Lobe1Roughness,float LobeMix,
							float3 WorldPos, float3 N, float3 V,float Occlusion,float EnvRotation,
							float ClearCoat,float ClearCoatRoughness,float3 ClearCoatNormal,
							out float3 IndirectLighting)
{
	IndirectLighting = half3(0,0,0);
	#ifndef SHADERGRAPH_PREVIEW
	float Roughness = (Lobe0Roughness + Lobe1Roughness) * 0.5;
	float NoV = saturate(abs(dot(N,V)) + 1e-5);
	float MainLightShadow = clamp(GetMainLightShadow(WorldPos),0.35,1.0);
	//Ao
	float SpecularOcclusion = GetSpecularOcclusion(NoV,Pow2(Roughness),Occlusion)*MainLightShadow;
	float3 DiffuseAO = AOMultiBounce(DiffuseColor,Occlusion);
	float3 SpecularAO = AOMultiBounce(SpecularColor,SpecularOcclusion);
	//SH
	float3 RadianceSH = SampleSH(N);
	float3 IndirectDiffuse = RadianceSH * DiffuseColor * DiffuseAO;
	#if defined(_SH_OFF)
		IndirectDiffuse = half3(0,0,0);
	#endif
	//IBL
	half3 R = reflect(-V,N);
	R = RotateDirection(R,EnvRotation);
	// half3 SpeucularLD = GlossyEnvironmentReflection(R,WorldPos,Roughness,Occlusion);
	// half3 SpecularDFG = EnvBRDFApprox(SpecularColor,Roughness,NoV);
	half3 SpecularLobe0 = SpecularIBL(R,WorldPos,Lobe0Roughness,SpecularColor,NoV);
	half3 SpecularLobe1 = SpecularIBL(R,WorldPos,Lobe1Roughness,SpecularColor,NoV);
	half3 DualLobe = lerp(SpecularLobe0,SpecularLobe1, 1.0 - LobeMix);
	float3 IndirectSpecular = DualLobe * SpecularAO;
	#if defined(_IBL_OFF)
		IndirectSpecular = half3(0,0,0);
	#endif
	//ClearCoat
	half3 R_ClearCoat = reflect(-V,ClearCoatNormal);
	float NoV_ClearCoat = saturate(abs(dot(ClearCoatNormal,V)) + 1e-5);
	half3 ClearCoatLobe = SpecularIBL(R_ClearCoat,WorldPos,ClearCoatRoughness,float3(0.04,0.04,0.04),NoV_ClearCoat);
	half3 IndirectClearCoat = ClearCoatLobe * ClearCoat * SpecularAO;

	float3 EnergyLoss = F_Schlick_UE4( float3(0.04,0.04,0.04), NoV_ClearCoat ) * ClearCoat;
	IndirectDiffuse = IndirectDiffuse * (1.0 - EnergyLoss);
	IndirectSpecular = IndirectSpecular * (1.0 - EnergyLoss);
	
	IndirectLighting = IndirectDiffuse + IndirectSpecular+IndirectClearCoat;
	#endif
}

#endif