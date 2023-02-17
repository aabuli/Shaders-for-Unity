Shader "Unlit/Gooch"
{
    Properties
    {
        _Albedo ("Albedo", Color) = (1,1,1,1)
        _Smoothness ("Smoothness", Range(0.01, 1)) = 0.5
        _Warm ("Warm Color", Color) = (1,1,1,1)
        _Cool ("Cool Color", Color) = (1,1,1,1)
        _Alpha ("Alpha", Range(0.01, 1)) = 0.5
        _Beta ("Beta", Range(0.01, 1)) = 0.5
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                //float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Albedo, _Warm, _Cool;
            float _Smoothness, _Alpha, _Beta;

            struct v2f
            {
                //float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                i.normal = normalize(i.normal);
                float3 lightDir = normalize(float3(1, 1, 0));
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                float3 reflectionDir = reflect(-lightDir, i.normal);
                float3 specular = DotClamped(viewDir, reflectionDir);
                specular = pow(specular, _Smoothness * 500);

                float goochDiffuse = (1.0f + dot(lightDir, i.normal)) / 2.0f;

                float3 kCool = _Cool.rgb + _Alpha * _Albedo.rgb;
                float3 kWarm = _Warm.rgb + _Beta * _Albedo.rgb;

                float3 gooch = (goochDiffuse * kWarm) + ((1 - goochDiffuse) * kCool);

                return float4(gooch + specular, 1.0f);
            }
            ENDCG
        }

    }
}
