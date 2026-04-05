Shader "VertigoVault/ProceduralRustPBR"
{
    // ────────────────────────────────────────────────────────
    //  ProceduralRustPBR.shader — Vertigo Vault (URP)
    //  텍스처 없이 절차적으로 녹을 생성하는 PBR 셰이더
    //  스캐폴딩 파이프, 철골 구조물에 사용
    // ────────────────────────────────────────────────────────
    Properties
    {
        [Header(Base Metal)]
        _MetalColor      ("Clean Metal Color", Color)   = (0.22, 0.22, 0.24, 1)
        _MetalSmoothness ("Metal Smoothness",  Range(0,1)) = 0.65
        _Metallic        ("Metallic",          Range(0,1)) = 0.95

        [Header(Rust)]
        _RustColor1      ("Rust Color Dark",   Color)   = (0.42, 0.18, 0.06, 1)
        _RustColor2      ("Rust Color Mid",    Color)   = (0.60, 0.28, 0.08, 1)
        _RustColor3      ("Rust Color Bright", Color)   = (0.72, 0.40, 0.12, 1)
        _RustAmount      ("Rust Amount",       Range(0,1)) = 0.45
        _RustSharpness   ("Rust Edge Sharpness",Range(1,20)) = 6.0
        _RustScale       ("Rust Pattern Scale",Float)    = 4.5
        _RustSmoothness  ("Rust Smoothness",   Range(0,1)) = 0.08

        [Header(Scratches)]
        _ScratchColor    ("Scratch Color",     Color)   = (0.15, 0.15, 0.16, 1)
        _ScratchAmount   ("Scratch Amount",    Range(0,1)) = 0.20
        _ScratchScale    ("Scratch Scale",     Float)   = 12.0

        [Header(Normal)]
        _NormalStrength  ("Normal Strength",   Range(0,3)) = 1.2

        [Header(Stripe Safety Marking)]
        _StripeColor     ("Stripe Color",      Color)   = (0.82, 0.62, 0.05, 1)
        _StripeAmount    ("Stripe Amount",     Range(0,1)) = 0.0
        _StripeFreq      ("Stripe Frequency",  Float)   = 6.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex   Vert
            #pragma fragment Frag
            #pragma target   3.0
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MetalColor;
                float  _MetalSmoothness, _Metallic;
                float4 _RustColor1, _RustColor2, _RustColor3;
                float  _RustAmount, _RustSharpness, _RustScale, _RustSmoothness;
                float4 _ScratchColor;
                float  _ScratchAmount, _ScratchScale;
                float  _NormalStrength;
                float4 _StripeColor;
                float  _StripeAmount, _StripeFreq;
            CBUFFER_END

            struct Attributes
            {
                float4 posOS   : POSITION;
                float3 normalOS: NORMAL;
                float4 tangentOS: TANGENT;
                float2 uv      : TEXCOORD0;
            };
            struct Varyings
            {
                float4 posCS   : SV_POSITION;
                float2 uv      : TEXCOORD0;
                float3 normalWS: TEXCOORD1;
                float3 posWS   : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
            };

            // ── 절차적 노이즈 ───────────────────────────
            float hash(float2 p){ return frac(sin(dot(p,float2(127.1,311.7)))*43758.5); }
            float vnoise(float2 p)
            {
                float2 i=floor(p); float2 f=frac(p); f=f*f*(3-2*f);
                return lerp(lerp(hash(i),         hash(i+float2(1,0)),f.x),
                            lerp(hash(i+float2(0,1)),hash(i+float2(1,1)),f.x),f.y);
            }
            float fbm2(float2 p)
            {
                float v=0,a=0.5;
                for(int i=0;i<5;i++){ v+=a*vnoise(p); p*=2.1; a*=0.5; }
                return v;
            }

            Varyings Vert(Attributes v)
            {
                Varyings o;
                o.posWS    = TransformObjectToWorld(v.posOS.xyz);
                o.posCS    = TransformWorldToHClip(o.posWS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.uv       = v.uv;
                o.shadowCoord = TransformWorldToShadowCoord(o.posWS);
                return o;
            }

            half4 Frag(Varyings i) : SV_Target
            {
                float2 uv = i.uv;

                // ── 녹 마스크 ──
                float  rustNoise = fbm2(uv * _RustScale);
                float  rustMask  = saturate((rustNoise - (1 - _RustAmount)) * _RustSharpness);
                // 녹 색상 (3단계 그라디언트)
                float3 rustCol = lerp(_RustColor1.rgb, _RustColor2.rgb, rustNoise);
                rustCol        = lerp(rustCol, _RustColor3.rgb, rustNoise * rustNoise);

                // ── 스크래치 ──
                float scratchN  = fbm2(uv * _ScratchScale + float2(3.7, 1.2));
                float scratchM  = step(0.92, scratchN) * _ScratchAmount;

                // ── 안전 줄무늬 ──
                float stripe    = step(0.5, frac(uv.y * _StripeFreq)) * _StripeAmount;

                // ── 알베도 합성 ──
                float3 baseCol  = _MetalColor.rgb;
                float3 albedo   = lerp(baseCol, rustCol, rustMask);
                albedo          = lerp(albedo, _ScratchColor.rgb, scratchM);
                albedo          = lerp(albedo, _StripeColor.rgb,  stripe * (1 - rustMask));

                // ── PBR 값 ──
                float  metallic    = lerp(_Metallic, 0.0, rustMask * 1.2);
                float  smoothness  = lerp(_MetalSmoothness, _RustSmoothness, rustMask);
                smoothness         = lerp(smoothness, 0.15, scratchM);

                // ── 절차적 노멀 (높낮이 기반) ──
                float eps = 0.005;
                float hC  = fbm2(uv * _RustScale);
                float hR  = fbm2(uv * _RustScale + float2(eps, 0));
                float hU  = fbm2(uv * _RustScale + float2(0, eps));
                float3 nTang = normalize(float3(-(hR - hC)/eps * _NormalStrength,
                                                -(hU - hC)/eps * _NormalStrength, 1));
                float3 normalWS = normalize(i.normalWS + nTang * 0.5);

                // ── Lighting ──
                InputData inputData = (InputData)0;
                inputData.positionWS    = i.posWS;
                inputData.normalWS      = normalWS;
                inputData.viewDirectionWS = normalize(_WorldSpaceCameraPos - i.posWS);
                inputData.shadowCoord   = i.shadowCoord;
                inputData.fogCoord      = ComputeFogFactor(i.posCS.z);

                SurfaceData surface = (SurfaceData)0;
                surface.albedo      = albedo;
                surface.metallic    = metallic;
                surface.smoothness  = smoothness;
                surface.occlusion   = 1.0;
                surface.alpha       = 1.0;

                half4 color = UniversalFragmentPBR(inputData, surface);
                color.rgb   = MixFog(color.rgb, inputData.fogCoord);
                return color;
            }
            ENDHLSL
        }

        // Shadow caster pass
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            ZWrite On ZTest LEqual ColorMask 0
            HLSLPROGRAM
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
}
