Shader "VertigoVault/VertigoPostProcess"
{
    // ────────────────────────────────────────────────────────
    //  VertigoPostProcess.shader — Vertigo Vault (URP)
    //  아래를 볼 때 발동하는 포스트프로세스:
    //    - RGB 채널 분리 (색수차)
    //    - 배럴 왜곡 (렌즈 왜곡)
    //    - 비녜트 (가장자리 어둠)
    //    - 펄스 플래시 (공포 강조)
    //
    //  C# VertigoEffect.cs 에서 _Intensity를 0~1로 제어합니다.
    // ────────────────────────────────────────────────────────
    Properties
    {
        _MainTex         ("Screen Texture", 2D)         = "white" {}
        _Intensity       ("Effect Intensity", Range(0,1)) = 0.0
        _ChromaStrength  ("Chroma Strength",  Range(0,0.06)) = 0.025
        _BarrelStrength  ("Barrel Distortion",Range(0,0.5))  = 0.18
        _VignetteStrength("Vignette",         Range(0,1.5))  = 0.8
        _VignetteSoftness("Vignette Softness",Range(0.1,2))  = 0.6
        _PulseFreq       ("Pulse Frequency",  Float)         = 1.8
        _PulseAmt        ("Pulse Amount",     Range(0,0.3))  = 0.08
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        ZWrite Off ZTest Always Cull Off

        Pass
        {
            Name "VertigoPostProcessPass"
            HLSLPROGRAM
            #pragma vertex   VertFullscreen
            #pragma fragment FragVertigo
            #pragma target   3.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float  _Intensity;
                float  _ChromaStrength;
                float  _BarrelStrength;
                float  _VignetteStrength, _VignetteSoftness;
                float  _PulseFreq, _PulseAmt;
            CBUFFER_END

            struct Varyings { float4 posCS : SV_POSITION; float2 uv : TEXCOORD0; };

            // 배럴 왜곡 UV 계산
            float2 BarrelDistort(float2 uv, float strength)
            {
                float2 c  = uv - 0.5;
                float  r2 = dot(c, c);
                float  f  = 1.0 + r2 * strength * 2.0;
                return c / f + 0.5;
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

            half4 FragVertigo(Varyings i) : SV_Target
            {
                float t = _Intensity;
                if (t < 0.001) return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                // 펄스 (심박 느낌)
                float pulse = sin(_Time.y * _PulseFreq * PI * 2) * 0.5 + 0.5;
                float tPulse = t * (1 + pulse * _PulseAmt * t);

                // 배럴 왜곡
                float2 uvDist = BarrelDistort(i.uv, _BarrelStrength * tPulse);

                // RGB 채널 분리
                float chromaAmt = _ChromaStrength * tPulse;
                float2 c = uvDist - 0.5;
                float2 uvR = c * (1 + chromaAmt)     + 0.5;
                float2 uvG = c                         + 0.5;
                float2 uvB = c * (1 - chromaAmt * 0.8)+ 0.5;

                // 화면 경계 밖은 검정
                float2 clampR = saturate(uvR); float2 clampB = saturate(uvB);
                float  boundsR = step(abs(uvR.x-0.5), 0.5) * step(abs(uvR.y-0.5), 0.5);
                float  boundsB = step(abs(uvB.x-0.5), 0.5) * step(abs(uvB.y-0.5), 0.5);

                float r = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvR).r * boundsR;
                float g = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvG).g;
                float b = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvB).b * boundsB;

                half3 col = half3(r, g, b);

                // 비녜트
                float2 vigUV = uvDist - 0.5;
                float  vigR  = length(vigUV * float2(1.0, 1.3));
                float  vig   = smoothstep(_VignetteSoftness, 0.0, vigR - (1 - _VignetteStrength * tPulse) * 0.5);
                col *= vig;

                // 약한 채도 감소 (공포 효과)
                float lum = dot(col, half3(0.299, 0.587, 0.114));
                col = lerp(col, half3(lum, lum, lum), t * 0.25);

                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
