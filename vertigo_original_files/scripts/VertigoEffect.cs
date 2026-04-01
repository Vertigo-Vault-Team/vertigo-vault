// ============================================================
//  VertigoEffect.cs — Vertigo Vault (재작성)
//  아래를 볼수록 색수차 + FOV 축소 + 배럴왜곡 증가
//  VertigoPostProcess.shader의 _Intensity를 구동합니다.
// ============================================================
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[RequireComponent(typeof(Camera))]
public class VertigoEffect : MonoBehaviour
{
    [Header("시선 임계값")]
    [Range(0f,90f)] public float thresholdAngle    = 28f;
    [Range(0f,90f)] public float fullIntensityAngle = 68f;

    [Header("Post-Process Volume")]
    public Volume ppVolume;

    [Header("FOV")]
    public float baseFOV        = 90f;   // Quest 기본 FOV
    [Range(0f,20f)] public float maxFovReduction = 12f;

    [Header("Smoothing")]
    [Range(1f,12f)] public float smoothSpeed = 6f;

    // 셰이더 머티리얼 직접 제어 (FullScreen Pass 사용 시)
    [Header("Shader (Optional)")]
    public Material vertigoMaterial;
    static readonly int ID_Intensity = Shader.PropertyToID("_Intensity");

    Camera _cam;
    ChromaticAberration _ca;
    Vignette            _vig;
    float _intensity;

    void Start()
    {
        _cam = GetComponent<Camera>();
        _cam.fieldOfView = baseFOV;
        ppVolume?.profile.TryGet(out _ca);
        ppVolume?.profile.TryGet(out _vig);
    }

    void Update()
    {
        float target = CalcIntensity();
        _intensity = Mathf.Lerp(_intensity, target, Time.deltaTime * smoothSpeed);
        Apply(_intensity);
    }

    float CalcIntensity()
    {
        float pitch = transform.eulerAngles.x;
        if (pitch > 180f) pitch -= 360f;
        float downAngle = Mathf.Clamp(-pitch, 0f, 90f);
        if (downAngle <= thresholdAngle)       return 0f;
        if (downAngle >= fullIntensityAngle)   return 1f;
        return (downAngle - thresholdAngle) / (fullIntensityAngle - thresholdAngle);
    }

    void Apply(float t)
    {
        _cam.fieldOfView = baseFOV - maxFovReduction * t;

        if (_ca  != null) { _ca.active = true;  _ca.intensity.Override(t * 0.022f); }
        if (_vig != null) { _vig.active = true;  _vig.intensity.Override(t * 0.55f); }

        // VertigoPostProcess.shader 직접 제어
        if (vertigoMaterial) vertigoMaterial.SetFloat(ID_Intensity, t);

        // StaminaSystem 연동: 낮은 스태미나일 때 추가 강화
        if (StaminaSystem.Instance != null)
        {
            float staminaBoost = Mathf.Clamp01((1f - StaminaSystem.Instance.StaminaPercent) * 0.4f);
            float combined = Mathf.Clamp01(t + staminaBoost);
            if (vertigoMaterial) vertigoMaterial.SetFloat(ID_Intensity, combined);
        }
    }

    public void Pulse(float extra = 0.25f) =>
        _intensity = Mathf.Clamp01(_intensity + extra);

    public float Intensity => _intensity;

    void OnDestroy()
    {
        if (_cam) _cam.fieldOfView = baseFOV;
    }
}
