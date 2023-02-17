Shader "Custom/ToonShader"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
		_Color("Color", Color) = (0.5, 0.65, 1, 1)
		[HDR] _AmbientColor("Ambient Color", Color) = (0.4, 0.4, 0.4, 1)
		[HDR] _SpecularColor("Specular Color", Color) = (0.9, 0.9, 0.9, 1)
		_Glossiness("Glossiness", Float) = 32
		[HDR] _RimColor("Rim Color", Color) = (1,1,1,1)
		_RimAmount("Rim Amount", Range(0,1 )) = 0.716
		_RimThreshold("Rim Threshold", Range (0, 1)) = 0.1
	}
		SubShader
	{
		Pass
		{
			Tags
			{
				"LightMode" = "UniversalForward"
				"PassFlags" = "OnlyDirectional"
			}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float4 _AmbientColor;
			float4 _SpecularColor;
			float _Glossiness;
			float4 _RimColor;
			float _RimAmount;
			float _RimThreshold;

			struct appdata
			{
				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : NORMAL;
				float3 viewDir : TEXCOORD1;
				float4 shadowCoord : TEXCOORD2;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = TransformObjectToWorldNormal(v.normal);
				float3 worldPos = GetVertexPositionInputs(v.vertex.xyz).positionWS;
				o.viewDir = GetWorldSpaceViewDir(worldPos);
				o.shadowCoord = TransformWorldToShadowCoord(worldPos);

				return o;
			}


			float4 frag(v2f i) : SV_Target
			{
				// Light
				Light mainLight = GetMainLight(i.shadowCoord);
				float shadow = mainLight.shadowAttenuation;
				float3 normal = normalize(i.worldNormal);
				float3 lightDir = mainLight.direction;
				float3 viewDir = normalize(i.viewDir);		
				float4 mainLightColor = float4(mainLight.color, 1);

				float NdotL = max(0, dot(normal, lightDir));
				float lightIntensity = smoothstep(0, 0.02, NdotL * shadow);		
				float4 light = lightIntensity * mainLightColor;
				
				
				// Specular
				float3 halfVector = normalize(lightDir + viewDir);
				float NdotH = max(0, dot(normal, halfVector)); 
				float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);	
				float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
				float4 specular = specularIntensitySmooth * _SpecularColor;
				
				// Rim
				float4 rimDot = 1 - dot(viewDir, normal);
				float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
				rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
				float4 rim = rimIntensity * _RimColor;

				float4 sample = tex2D(_MainTex, i.uv);
				return _Color * sample * (_AmbientColor + light + specular + rim);
		
			}
			ENDHLSL
		}
			usePass "Universal Render Pipeline/Lit/ShadowCaster"
	}
}