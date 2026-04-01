Shader "VertigoVault/OvercastSky"
{
    // ────────────────────────────────────────────────────────
    //  OvercastSky.shader — Vertigo Vault (URP)
    //  절차적 구름을 가진 흐린 하늘 스카이박스
    //  사용법: Material → Shader → VertigoVault/OvercastSky
    //          Lighting → Environment → Skybox에 할당
    // ────────────────────────────────────────────────────────
    Properties
    {
        _SkyColorTop    ("Sky Top Color",    Color)  = (0.52, 0.55, 0.60, 1)
        _SkyColorHorizon("Sky Horizon",      Color)  = (0.72, 0.74, 0.76, 1)
        _FogColorBase   ("Fog Color",        Color)  = (0.80, 0.81, 0.82, 1)
        _HorizonHeight  ("Horizon Height",   Range(-1,1)) = 0.0
        _HorizonSharpness("Horizon Sharp",   Range(1,20)) = 6.0
        _CloudScale     ("Cloud Scale",      Float)  = 3.5
        _CloudSpeed     ("Cloud Speed",      Float)  = 0.012
        _CloudCoverage  ("Cloud Coverage",   Range(0,1)) = 0.72
        _CloudDensity   ("Cloud Density",    Range(0,1)) = 0.80
        _CloudBrightMin ("Cloud Dark",       Range(0,1)) = 0.55
        _CloudBrightMax ("Cloud Bright",     Range(0,1)) = 0.92
        _SunDirection   ("Sun Direction",    Vector) = (0.3, 0.2, 0.8, 0)
    }

    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background"
               "PreviewType"="Skybox" "RenderPipeline"="UniversalPipeline" }
        ZWrite Off Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex   Vert
            #pragma fragment Frag
            #pragma target   3.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _SkyColorTop, _SkyColorHorizon, _FogColorBase;
                float  _HorizonHeight, _HorizonSharpness;
                float  _CloudScale, _CloudSpeed, _CloudCoverage, _CloudDensity;
                float  _CloudBrightMin, _CloudBrightMax;
                float4 _SunDirection;
            CBUFFER_END

            struct Varyings { float4 pos : SV_POSITION; float3 dir : TEXCOORD0; };

            float hash2(float2 p){ return frac(sin(dot(p,float2(127.1,311.7)))*43758.5); }
            float noise2(float2 p)
            {
                float2 i=floor(p); float2 f=frac(p); f=f*f*(3-2*f);
                return lerp(lerp(hash2(i),         hash2(i+float2(1,0)),f.x),
                            lerp(hash2(i+float2(0,1)),hash2(i+float2(1,1)),f.x),f.y);
            }
            float cloudFBM(float2 uv)
            {
                float v=0; float a=0.5; float2 s=uv;
                for(int i=0;i<6;i++){ v+=a*noise2(s); s*=2.1+float2(0.1*i,0); a*=0.48; }
                return v;
            }

            Varyings Vert(float4 pos : POSITION)
            {
                Varyings o;
                o.pos = TransformObjectToHClip(pos.xyz);
                o.dir = pos.xyz;
                return o;
            }

            half4 Frag(Varyings i) : SV_Target
            {
                float3 dir = normalize(i.dir);

                // 하늘 그라디언트
                float  upness  = saturate(dir.y * _HorizonSharpness * 0.5 + 0.5 + _HorizonHeight);
                float3 skyBase = lerp(_SkyColorHorizon.rgb, _SkyColorTop.rgb, pow(upness, 0.7));

                // 구름 (구면 투영)
                float2 cloudUV  = dir.xz / (abs(dir.y) + 0.05) * _CloudScale;
                cloudUV        += _Time.y * _CloudSpeed;
                float  cloudRaw = cloudFBM(cloudUV);
                float  cloudMask= saturate((cloudRaw - (1-_CloudCoverage)) * 8.0);
                cloudMask       = pow(cloudMask, 0.6) * _CloudDensity * saturate(dir.y * 8 + 0.4);

                float  sunDot   = saturate(dot(dir, normalize(_SunDirection.xyz)));
                float  cloudBri = lerp(_CloudBrightMin, _CloudBrightMax, sunDot * 0.5 + cloudRaw * 0.5);
                float3 cloudCol = float3(cloudBri, cloudBri, cloudBri + 0.02);

                // 수평선 안개
                float  fogAmt   = saturate(1 - abs(dir.y) * 5.0);
                fogAmt          = pow(fogAmt, 2.5);

                float3 col = lerp(skyBase, cloudCol, cloudMask);
                col        = lerp(col, _FogColorBase.rgb, fogAmt * 0.55);

                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
