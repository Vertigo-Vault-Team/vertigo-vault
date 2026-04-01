using UnityEngine;

public class GrabSystem : MonoBehaviour
{
    [Header("Grab Detection")]
    public float grabRadius     = 0.08f;
    public LayerMask grabLayers = ~0;

    [Header("Grab Audio")]
    public AudioSource grabSource;
    public AudioClip[] metalGrabClips;   // grab_metal_1~2
    public AudioClip[] woodGrabClips;    // grab_wood_1~3
    public AudioClip[] creakClips;       // creak_metal_1~4
    [Range(0f,1f)] public float creakChance = 0.35f;

    [Header("Haptics (Meta Quest)")]
    [Range(0f,1f)] public float hapticAmplitude = 0.4f;
    public float hapticDuration = 0.08f;

    [Header("Stamina Drain")]
    public float staminaDrainRate = 10f;

    bool _isGrabbing;
    bool _isMetal;

    // XR Interaction Toolkit 연동 시 이 메서드들을 XRGrabInteractable 이벤트에 연결
    public void OnGrabStart(bool isMetal, Vector3 grabPoint)
    {
        _isGrabbing = true;
        _isMetal    = isMetal;
        StaminaSystem.Instance?.SetDraining(true);

        PlayGrabSound(isMetal);
        TriggerHaptic();

        // 삐걱 소리 확률
        if (Random.value < creakChance)
            PlayCreak();

        // 바람 시스템에 잡기 이벤트 알림
        WindSystem.Instance?.RequestGust(0.2f);
    }

    public void OnGrabEnd()
    {
        _isGrabbing = false;
        StaminaSystem.Instance?.SetDraining(false);
    }

    void PlayGrabSound(bool metal)
    {
        if (!grabSource) return;
        AudioClip[] clips = metal ? metalGrabClips : woodGrabClips;
        if (clips == null || clips.Length == 0) return;
        grabSource.pitch  = Random.Range(0.92f, 1.08f);
        grabSource.volume = 0.75f;
        grabSource.PlayOneShot(clips[Random.Range(0, clips.Length)]);
    }

    void PlayCreak()
    {
        if (!grabSource || creakClips == null || creakClips.Length == 0) return;
        grabSource.volume = 0.50f;
        grabSource.pitch  = Random.Range(0.85f, 1.15f);
        grabSource.PlayOneShot(creakClips[Random.Range(0, creakClips.Length)]);
    }

    void TriggerHaptic()
    {
#if UNITY_ANDROID
        // Meta Quest 햅틱 (OVR 플러그인 사용 시)
        // OVRInput.SetControllerVibration(hapticAmplitude, hapticAmplitude,
        //     OVRInput.Controller.RTouch);
        // 0.08초 후 정지:
        // Invoke(nameof(StopHaptic), hapticDuration);
#endif
    }

    public bool IsGrabbing => _isGrabbing;
}
