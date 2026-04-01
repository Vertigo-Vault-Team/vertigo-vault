using System.Collections;
using UnityEngine;

public class AmbientSoundManager : MonoBehaviour
{
    [Header("Sources")]
    public AudioSource droneSource;
    public AudioSource gustSource;
    public AudioSource howlSource;
    public AudioSource creakSource;
    public AudioSource constructionSource;

    [Header("Clips")]
    public AudioClip   droneClip;
    public AudioClip[] gustClips;
    public AudioClip[] creakClips;
    public AudioClip   constructionDistant;

    [Header("Volume Targets")]
    public float droneMaxVolume        = 0.45f;
    public float gustMaxVolume         = 0.80f;
    public float creakMaxVolume        = 0.60f;
    public float constructionVolume    = 0.20f;

    [Header("Intervals")]
    public float creakIntervalMin = 4f;
    public float creakIntervalMax = 12f;

    void Start()
    {
        PlayLoop(droneSource, droneClip, 0f);
        PlayLoop(constructionSource, constructionDistant, constructionVolume);
        StartCoroutine(CreakRoutine());
    }

    void Update()
    {
        float h = WindSystem.Instance?.HeightFactor ?? 0f;
        float g = WindSystem.Instance?.GustIntensity ?? 0f;

        if (droneSource)
            droneSource.volume = Mathf.Lerp(droneSource.volume,
                                             h * droneMaxVolume, Time.deltaTime * 2f);
    }

    IEnumerator CreakRoutine()
    {
        while (true)
        {
            float h = WindSystem.Instance?.HeightFactor ?? 0.5f;
            float wait = Random.Range(creakIntervalMin, creakIntervalMax) * Mathf.Lerp(1f, 0.5f, h);
            yield return new WaitForSeconds(wait);
            if (creakSource && creakClips?.Length > 0)
            {
                creakSource.volume = creakMaxVolume * Mathf.Clamp01(h * 1.5f);
                creakSource.pitch  = Random.Range(0.8f, 1.25f);
                creakSource.PlayOneShot(creakClips[Random.Range(0, creakClips.Length)]);
            }
        }
    }

    void PlayLoop(AudioSource src, AudioClip clip, float vol)
    {
        if (!src || !clip) return;
        src.clip   = clip; src.loop = true;
        src.volume = vol;  src.Play();
    }
}
