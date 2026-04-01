using UnityEngine;
using UnityEngine.Events;

public class CollectibleSystem : MonoBehaviour
{
    [Header("Collectible Settings")]
    public string collectibleTag  = "Toolbox";
    public float  collectRadius   = 0.8f;
    public Transform playerHand;

    [Header("Feedback")]
    public AudioSource collectSource;
    public AudioClip   collectSound;
    public GameObject  collectVFX;       // 파티클 프리팹

    [Header("Score")]
    public int totalToolboxes = 0;       // 씬에서 자동 카운트
    int _collected = 0;

    [Header("Events")]
    public UnityEvent<int, int> onCollect;  // (collected, total)
    public UnityEvent           onAllCollected;

    void Start()
    {
        totalToolboxes = FindObjectsByType<ToolboxItem>(FindObjectsSortMode.None).Length;
    }

    void Update()
    {
        if (!playerHand) return;
        // 반경 내 공구함 감지
        Collider[] hits = Physics.OverlapSphere(playerHand.position, collectRadius,
                                                 LayerMask.GetMask("Collectible"));
        foreach (var hit in hits)
        {
            var item = hit.GetComponent<ToolboxItem>();
            if (item != null && !item.IsCollected)
                Collect(item);
        }
    }

    void Collect(ToolboxItem item)
    {
        item.Collect();
        _collected++;

        if (collectSource && collectSound)
            collectSource.PlayOneShot(collectSound);

        if (collectVFX)
            Instantiate(collectVFX, item.transform.position, Quaternion.identity);

        // 수집 시 잠깐 아래를 유도 (버티고 강화)
        FindFirstObjectByType<VertigoEffect>()?.Pulse(0.15f);

        onCollect?.Invoke(_collected, totalToolboxes);
        if (_collected >= totalToolboxes)
            onAllCollected?.Invoke();
    }

    public int Collected => _collected;
    public int Total     => totalToolboxes;
}

// 개별 공구함 아이템
public class ToolboxItem : MonoBehaviour
{
    [Header("Hover Bob")]
    public float bobHeight = 0.08f;
    public float bobSpeed  = 1.2f;
    public float rotSpeed  = 45f;

    bool    _collected;
    Vector3 _startPos;

    void Start()  => _startPos = transform.position;

    void Update()
    {
        if (_collected) return;
        transform.position = _startPos + Vector3.up *
            (Mathf.Sin(Time.time * bobSpeed) * bobHeight);
        transform.Rotate(0, rotSpeed * Time.deltaTime, 0);
    }

    public void Collect()
    {
        _collected = true;
        gameObject.SetActive(false);
    }

    public bool IsCollected => _collected;
}
