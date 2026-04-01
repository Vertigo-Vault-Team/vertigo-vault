using UnityEngine;
using UnityEngine.UI;

public class StaminaSystem : MonoBehaviour
{
    public static StaminaSystem Instance { get; private set; }

    [Header("Stamina")]
    public float maxStamina  = 100f;
    [Range(1f,25f)] public float drainRate = 10f;   // 매달릴 때 초당
    [Range(1f,25f)] public float regenRate = 6f;    // 쉴 때 초당
    [Range(0f,1f)]  public float criticalThreshold = 0.25f;

    [Header("Breathing Audio")]
    public AudioSource breathSource;
    public AudioClip   breathingLoop;
    [Range(0f,1f)] public float maxBreathVolume = 0.65f;

    [Header("UI")]
    public Slider staminaSlider;
    public Image  staminaFill;   // 슬라이더 Fill 이미지
    public Color  colorFull     = new Color(0.3f,0.85f,0.4f);
    public Color  colorLow      = new Color(0.95f,0.35f,0.15f);

    float _stamina;
    bool  _isDraining;
    bool  _isCritical;

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        _stamina = maxStamina;
    }

    void Start()
    {
        if (breathSource && breathingLoop)
        {
            breathSource.clip   = breathingLoop;
            breathSource.loop   = true;
            breathSource.volume = 0f;
            breathSource.Play();
        }
    }

    void Update()
    {
        // 스태미나 변화
        if (_isDraining)
            _stamina = Mathf.Max(0f, _stamina - drainRate * Time.deltaTime);
        else
            _stamina = Mathf.Min(maxStamina, _stamina + regenRate * Time.deltaTime);

        float pct = StaminaPercent;
        _isCritical = pct < criticalThreshold;

        // 숨소리 볼륨 (스태미나 낮을수록 커짐)
        if (breathSource)
        {
            float breathTarget = pct < 0.6f
                ? (0.6f - pct) / 0.6f * maxBreathVolume
                : 0f;
            breathSource.volume = Mathf.Lerp(breathSource.volume, breathTarget,
                                              Time.deltaTime * 3f);
            // 숨찰수록 피치 올라감
            breathSource.pitch  = 1f + (1f - pct) * 0.3f;
        }

        // UI 업데이트
        if (staminaSlider) staminaSlider.value = pct;
        if (staminaFill)   staminaFill.color   = Color.Lerp(colorLow, colorFull, pct);

        // 위험 상태 → VertigoEffect 펄스
        if (_isCritical && VertigoEffect != null)
            VertigoEffect.Pulse(0.05f * Time.deltaTime);

        // WindSystem 연동 — 스태미나 낮으면 돌풍이 더 무섭게 느껴짐
        // (WindSystem이 HeightFactor와 GustIntensity를 올려줌)
    }

    VertigoEffect _ve;
    VertigoEffect VertigoEffect => _ve ??= FindFirstObjectByType<VertigoEffect>();

    public void SetDraining(bool draining) => _isDraining = draining;
    public void ConsumeStamina(float amount) => _stamina = Mathf.Max(0f, _stamina - amount);
    public void RestoreStamina(float amount) => _stamina = Mathf.Min(maxStamina, _stamina + amount);

    public float StaminaPercent => _stamina / maxStamina;
    public bool  IsCritical     => _isCritical;
    public bool  IsExhausted    => _stamina <= 0f;
}
