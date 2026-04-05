Shader "VertigoVault/WindParticle"
{
    // ────────────────────────────────────────────────────────
    //  WindParticle.shader — Vertigo Vault (URP)
    //  바람 먼지/파편 파티클 셰이더
    //  고도에 따라 밝기·불투명도 자동 변화
    // ────────────────────────────────────────────────────────
    Properties
    {
        _BaseColor   ("Base Color",    Color)   = (0.82, 0.80, 0.76, 0.6)
        _SpeedColor  ("Speed Tint",    Color)   = (0.90, 0.88, 0.84, 0.8)
        _SoftParticle("Soft Particle", Range(0.1, 5)) = 1.5
        _HeightFade  ("Height Fade Start Y", Float) = 5.0
        _HeightFadeEnd("Height Fade End Y",  Float) = 80.0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent"
               "IgnoreProjector"="True" "RenderPipeline"="UniversalPipeline" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex   Vert
            #pragma fragment Frag
            #pragma target   2.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor, _SpeedColor;
                float  _SoftParticle, _HeightFade, _HeightFadeEnd;
            CBUFFER_END

            struct Attributes
            {
                float4 posOS  : POSITION;
                float4 color  : COLOR;
                float2 uv     : TEXCOORD0;
                float3 vel    : TEXCOORD1;   // custom particle velocity stream
            };
            struct Varyings
            {
                float4 posCS  : SV_POSITION;
                float4 color  : COLOR;
                float2 uv     : TEXCOORD0;
                float4 posNDC : TEXCOORD1;
                float  worldY : TEXCOORD2;
            };

            Varyings Vert(Attributes v)
            {
                Varyings o;
                float3 posWS = TransformObjectToWorld(v.posOS.xyz);
                o.posCS  = TransformWorldToHClip(posWS);
                o.color  = v.color;
                o.uv     = v.uv;
                o.posNDC = ComputeScreenPos(o.posCS);
                o.worldY = posWS.y;
                return o;
            }

            half4 Frag(Varyings i) : SV_Target
            {
                // 원형 파티클 마스크
                float2 uvc = i.uv - 0.5;
                float  r   = length(uvc);
                float  mask = smoothstep(0.5, 0.3, r);
                if (mask < 0.01) discard;

                // 속도에 따른 색상
                half4 col = lerp(_BaseColor, _SpeedColor, saturate(i.color.a));
                col.rgb  *= i.color.rgb;

                // 고도 페이드
                float hFade = saturate((i.worldY - _HeightFade) / (_HeightFadeEnd - _HeightFade));

                // Soft particle (깊이 비교)
                float2 screenUV  = i.posNDC.xy / i.posNDC.w;
                float  sceneZ    = LinearEyeDepth(SampleSceneDepth(screenUV),
                                                   _ZBufferParams);
                float  partZ     = i.posNDC.w;
                float  softFade  = saturate((sceneZ - partZ) / _SoftParticle);

                col.a *= mask * softFade * hFade * i.color.a;
                return col;
            }
            ENDHLSL
        }
    }
}
