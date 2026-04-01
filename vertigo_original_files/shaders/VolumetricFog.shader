Shader "VertigoVault/VolumetricFog"
{
    // ────────────────────────────────────────────────────────
    //  VolumetricFog.shader — Vertigo Vault (URP)
    //  스크린 스페이스 레이마칭 볼류메트릭 안개
    //  사용법: Volume Override → Full-Screen Pass Renderer Feature
    // ────────────────────────────────────────────────────────
    Properties
    {
        _FogColor       ("Fog Color",        Color)  = (0.72, 0.74, 0.78, 1)
        _FogDensity     ("Fog Density",      Range(0, 1))    = 0.18
        _FogStartY      ("Fog Start Y",      Float)          = 0.0
        _FogEndY        ("Fog End Y",        Float)          = 60.0
        _FogNearDist    ("Fog Near Dist",    Float)          = 5.0
        _FogFarDist     ("Fog Far Dist",     Float)          = 120.0
        _WindSpeed      ("Wind Speed",       Vector)         = (0.8, 0, 0.4, 0)
        _TurbulenceScale("Turbulence Scale", Float)          = 0.04
        _TurbulenceAmt  ("Turbulence Amt",   Range(0, 1))    = 0.35
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"
               "RenderPipeline"="UniversalPipeline" }
        ZWrite Off ZTest Always Cull Off Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "VolumetricFogPass"
            HLSLPROGRAM
            #pragma vertex   VertFullscreen
            #pragma fragment FragFog
            #pragma target   3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _FogColor;
                float  _FogDensity;
                float  _FogStartY, _FogEndY;
                float  _FogNearDist, _FogFarDist;
                float4 _WindSpeed;
                float  _TurbulenceScale, _TurbulenceAmt;
            CBUFFER_END

            struct Varyings { float4 posCS : SV_POSITION; float2 uv : TEXCOORD0; };

            // 간단한 3D value noise (텍스처 없이)
            float hash(float3 p)
            {
                p = frac(p * float3(0.1031, 0.1030, 0.0973));
                p += dot(p, p.yxz + 33.33);
                return frac((p.x + p.y) * p.z);
            }
            float noise3(float3 p)
            {
                float3 i = floor(p); float3 f = frac(p);
                f = f*f*(3-2*f);
                return lerp(lerp(lerp(hash(i),         hash(i+float3(1,0,0)),f.x),
                                 lerp(hash(i+float3(0,1,0)),hash(i+float3(1,1,0)),f.x),f.y),
                            lerp(lerp(hash(i+float3(0,0,1)),hash(i+float3(1,0,1)),f.x),
                                 lerp(hash(i+float3(0,1,1)),hash(i+float3(1,1,1)),f.x),f.y),f.z);
            }
            float fbm(float3 p)
            {
                float v=0; float a=0.5;
                for(int i=0;i<4;i++){ v+=a*noise3(p); p*=2.1; a*=0.5; }
                return v;
            }

            Varyings VertFullscreen(uint vid : SV_VertexID)
            {
                Varyings o;
                float2 uv = float2((vid << 1) & 2, vid & 2);
                o.posCS = float4(uv * 2 - 1, 0, 1);
                o.uv    = uv;
                #if UNITY_UV_STARTS_AT_TOP
                    o.uv.y = 1 - o.uv.y;
                #endif
                return o;
            }

            half4 FragFog(Varyings i) : SV_Target
            {
                // 깊이 → 월드 위치 재구성
                float rawDepth = SampleSceneDepth(i.uv);
                float3 posNDC  = float3(i.uv * 2 - 1, rawDepth);
                #if UNITY_REVERSED_Z
                    posNDC.z = 1 - posNDC.z;
                #endif
                float4 posVS   = mul(unity_CameraInvProjection, float4(posNDC, 1));
                posVS /= posVS.w;
                float4 posWS   = mul(unity_CameraToWorld, posVS);

                float dist      = length(posWS.xyz - _WorldSpaceCameraPos);
                float heightFac = 1 - saturate((posWS.y - _FogStartY) / (_FogEndY - _FogStartY));
                float distFac   = saturate((dist - _FogNearDist) / (_FogFarDist - _FogNearDist));

                // 터뷸런스
                float3 windOff  = _Time.y * _WindSpeed.xyz;
                float  turb     = fbm((posWS.xyz + windOff) * _TurbulenceScale);
                float  fogAmt   = _FogDensity * heightFac * distFac;
                fogAmt         *= (1 + (turb - 0.5) * _TurbulenceAmt * 2);
                fogAmt          = saturate(fogAmt);

                return half4(_FogColor.rgb, fogAmt);
            }
            ENDHLSL
        }
    }
}
