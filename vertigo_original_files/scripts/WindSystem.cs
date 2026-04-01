// WindSystem.cs — Vertigo Vault
// 전역 바람 시스템: 돌풍 스케줄 + 파티클 + 전역 셰이더 프로퍼티 제어
// 씬의 모든 바람 관련 요소를 하나의 시스템으로 통합합니다.

using System.Collections;
using UnityEngine;
using UnityEngine.VFX;

public class WindSystem : MonoBehaviour
{
    public static WindSystem Instance { get; private set; }

    [Header("Height Reference")]
    public Transform playerTransform;
    public float groundY   = 0f;
    public float maxHeightY = 200f;

    [Header("Gust Schedule")]
    public float gustIntervalMin = 5f;
    public float gustIntervalMax = 18f;
    [Range(0f,1f)] public float gustIntensity = 0.0f;   // 현재 강도 (0~1)

    [Header("Wind Direction")]
    public Vector3 windDirection = new Vector3(1, 0, 0.3f);
    [Range(0f, 30f)] public float windAngleVariation = 15f;

    [Header("Particles")]
    public ParticleSystem windParticles;
    public float maxEmission = 120f;
    public float maxSpeed    = 20f;

    [Header("Audio")]
    public AudioSource droneSource;
    public AudioClip   droneClip;
    public AudioSource gustSource;
    public AudioClip[] gustClips;   // light, medium, heavy

    [Header("Global Shader IDs")]
    // 셰이더에서 _WindDirection, _WindIntensity, _HeightFactor 참조
    static readonly int ID_WindDir   = Shader.PropertyToID("_WindDirection");
    static readonly int ID_WindInt   = Shader.PropertyToID("_WindIntensity");
    static readonly int ID_HeightFac = Shader.PropertyToID("_HeightFactor");
    static readonly int ID_GustAmt   = Shader.PropertyToID("_GustAmount");

    float _heightFactor;
    float _smoothedGust;

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
    }

    void Start()
    {
        if (droneSource && droneClip)
        {
            droneSource.clip  = droneClip;
            droneSource.loop  = true;
            droneSource.volume = 0f;
            droneSource.Play();
        }
        StartCoroutine(GustScheduler());
    }

    void Update()
    {
        // 높이 계산
        if (playerTransform)
        {
            float h = playerTransform.position.y - groundY;
            _heightFactor = Mathf.Clamp01(h / (maxHeightY - groundY));
        }

        // 드론 볼륨
        if (droneSource)
            droneSource.volume = Mathf.Lerp(droneSource.volume,
                                             _heightFactor * 0.5f, Time.deltaTime * 3f);

        // 파티클 업데이트
        UpdateParticles();

        // 전역 셰이더 프로퍼티 (VolumetricFog, ProceduralRust 등이 읽음)
        _smoothedGust = Mathf.Lerp(_smoothedGust, gustIntensity, Time.deltaTime * 4f);
        Shader.SetGlobalVector(ID_WindDir,   windDirection.normalized);
        Shader.SetGlobalFloat(ID_WindInt,    _heightFactor);
        Shader.SetGlobalFloat(ID_HeightFac,  _heightFactor);
        Shader.SetGlobalFloat(ID_GustAmt,    _smoothedGust);
    }

    IEnumerator GustScheduler()
    {
        while (true)
        {
            float wait = Random.Range(gustIntervalMin, gustIntervalMax);
            wait *= Mathf.Lerp(1f, 0.4f, _heightFactor);
            yield return new WaitForSeconds(wait);

            if (_heightFactor < 0.05f) continue;

            // 돌풍 강도 (높이에 비례)
            float intensity = Random.Range(0.3f, 1.0f) * _heightFactor;
            StartCoroutine(GustPulse(intensity));
        }
    }

    IEnumerator GustPulse(float intensity)
    {
        float peak = 0f, dur = Mathf.Lerp(1.5f, 3.5f, intensity);
        // 방향 살짝 틀기
        float angle = Random.Range(-windAngleVariation, windAngleVariation);
        windDirection = Quaternion.Euler(0, angle, 0) * windDirection;

        // 돌풍 사운드
        if (gustSource && gustClips != null && gustClips.Length > 0)
        {
            int tier = intensity < 0.35f ? 0 : intensity < 0.7f ? 1 : Mathf.Min(2, gustClips.Length-1);
            gustSource.volume = intensity * 0.9f;
            gustSource.pitch  = Random.Range(0.9f, 1.15f);
            gustSource.PlayOneShot(gustClips[tier]);
        }

        // 강도 커브
        float t = 0f;
        while (t < dur)
        {
            float progress = t / dur;
            peak = progress < 0.15f
                 ? Mathf.SmoothStep(0, intensity, progress / 0.15f)
                 : Mathf.SmoothStep(intensity, 0, (progress - 0.15f) / 0.85f);
            gustIntensity = peak;
            t += Time.deltaTime;
            yield return null;
        }
        gustIntensity = 0f;
    }

    void UpdateParticles()
    {
        if (!windParticles) return;
        var emission = windParticles.emission;
        emission.rateOverTime = maxEmission * _heightFactor * (1 + _smoothedGust);
        var vel = windParticles.velocityOverLifetime;
        float spd = maxSpeed * _heightFactor * (1 + _smoothedGust * 0.5f);
        vel.x = new ParticleSystem.MinMaxCurve(-spd * 0.8f, -spd);
        vel.y = new ParticleSystem.MinMaxCurve(-spd * 0.05f, spd * 0.05f);
    }

    // 외부 호출용 — CranePayloadSwing 등에서 돌풍 충격 요청
    public void RequestGust(float intensity = 0.6f) =>
        StartCoroutine(GustPulse(Mathf.Clamp01(intensity)));

    public float HeightFactor  => _heightFactor;
    public float GustIntensity => _smoothedGust;
}
