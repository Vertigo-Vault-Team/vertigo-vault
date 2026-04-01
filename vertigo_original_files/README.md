# Vertigo Vault

> A first-person VR climbing game for Meta Quest designed to trigger genuine acrophobia.  
> Scale an unfinished skyscraper across scaffolding, narrow planks, and rusted steel — one wrong step and it's a long way down.

---

## 📁 Repository Structure

```
vertigo-vault/
├── Assets/
│   ├── Models/                    3D mesh assets (OBJ + MTL)
│   │   ├── scaffolding_kit.obj / .mtl
│   │   ├── rusty_pipe.obj / .mtl
│   │   ├── wood_plank_pristine.obj / .mtl
│   │   ├── wood_plank_cracked.obj / .mtl
│   │   ├── concrete_block.obj / .mtl
│   │   ├── rebar_cluster.obj / .mtl
│   │   ├── temp_fencing.obj / .mtl
│   │   ├── pulley_system.obj / .mtl
│   │   ├── cable_spool.obj / .mtl
│   │   ├── safety_net_fabric.obj / .mtl
│   │   ├── steel_mesh_net.obj / .mtl
│   │   ├── toolbox_collectible.obj / .mtl
│   │   ├── midground_building.obj / .mtl
│   │   └── crane_standalone.obj / .mtl
│   │
│   ├── Audio/                     Procedural WAV sound effects
│   │   ├── wind_drone_loop.wav
│   │   ├── wind_gust_light.wav
│   │   ├── wind_gust_medium.wav
│   │   ├── wind_gust_heavy.wav
│   │   ├── creak_metal_1.wav
│   │   ├── creak_metal_2.wav
│   │   ├── creak_metal_3.wav
│   │   ├── creak_metal_4.wav
│   │   ├── grab_metal_1.wav
│   │   ├── grab_metal_2.wav
│   │   ├── grab_wood_1.wav
│   │   ├── grab_wood_2.wav
│   │   ├── grab_wood_3.wav
│   │   ├── breathing_heavy_loop.wav
│   │   └── construction_distant.wav
│   │
│   ├── Shaders/                   URP HLSL shaders
│   │   ├── VolumetricFog.shader
│   │   ├── OvercastSky.shader
│   │   ├── VertigoPostProcess.shader
│   │   ├── WindParticle.shader
│   │   └── ProceduralRustPBR.shader
│   │
│   └── Scripts/                   Unity C# scripts
│       ├── WindSystem.cs
│       ├── VertigoEffect.cs
│       ├── StaminaSystem.cs
│       ├── GrabSystem.cs
│       ├── HeightTracker.cs
│       ├── BreakableProp.cs
│       ├── CollectibleSystem.cs
│       ├── AmbientSoundManager.cs
│       ├── CraneController.cs
│       └── VertigoTriggerZone.cs
│
└── README.md
```

---

## 🗂️ Asset Overview

### 3D Models — 14 assets (OBJ + MTL, no external textures)

All models are self-contained: color and material data are embedded directly in the `.mtl` file as `Kd` values, so **no PNG textures are needed**. Just drop the `.obj` and `.mtl` into the same Unity folder and import.

#### Map Base

| Asset | Tris | Description |
|---|---|---|
| `scaffolding_kit` | 832 | Modular scaffolding — steel pipes, cross braces, clamps, wide/narrow platforms |
| `rusty_pipe` | 172 | Standalone pipe with procedural rust patches and a broken end segment |
| `wood_plank_pristine` | 72 | Clean plank set with support joists, warm grain color |
| `wood_plank_cracked` | 96 | Weathered planks with visible crack geometry and darkened grain |
| `concrete_block` | 132 | Construction block with cast-in lifting loops and exposed rebar stubs |
| `rebar_cluster` | 156 | Bundle of 4 rebar rods bound with tie wire |
| `temp_fencing` | 412 | Temporary site fencing with warning tape and weighted base feet |

#### Props

| Asset | Tris | Description |
|---|---|---|
| `pulley_system` | 564 | Dual-wheel pulley block with suspended hoist cables |
| `cable_spool` | 840 | Heavy-duty cable spool on a welded steel support frame |
| `safety_net_fabric` | 736 | Yellow fabric safety net with eyelet anchor rings |
| `steel_mesh_net` | 704 | Diagonal chain-link steel mesh panel |
| `toolbox_collectible` | 156 | Red metal toolbox with lock, hinge, handle — hidden collectible |
| `crane_standalone` | 1,796 | Full tower crane with jib, counter-jib, trolley, hoist cables, and hanging payload crate |

#### Background

| Asset | Tris | Description |
|---|---|---|
| `midground_building` | 3,336 | Low-poly skyscraper for background depth with window grid and rooftop antenna |

---

### 🔊 Audio — 15 WAV files (44100 Hz / 16-bit / Mono)

All audio is procedurally synthesized — no third-party samples.

| File | Duration | Description |
|---|---|---|
| `wind_drone_loop` | 4.0s | Low-frequency wind drone, loop-ready with cross-fade |
| `wind_gust_light` | 2.0s | Light rolling gust with fast attack |
| `wind_gust_medium` | 2.5s | Medium gust, wider frequency range |
| `wind_gust_heavy` | 3.0s | Heavy howling burst for high altitude |
| `creak_metal_1~4` | 0.8–1.5s | Structural metal creak variants with pitch slide |
| `grab_metal_1~2` | 0.5s | Metal pipe grab — impact transient + ring decay |
| `grab_wood_1~3` | 0.4s | Wood plank grab — dull thud with optional creak |
| `breathing_heavy_loop` | 3.0s | Labored breathing loop for low-stamina feedback |
| `construction_distant` | 5.0s | Distant construction ambience — machinery hum and impact hits |

---

### 🎨 Shaders — 5 URP HLSL shaders

| File | Description |
|---|---|
| `VolumetricFog` | Screen-space raymarched fog with wind-driven turbulence |
| `OvercastSky` | Skybox with FBM procedural clouds and horizon fog band |
| `VertigoPostProcess` | Chromatic aberration + barrel distortion + vignette — intensity driven by `VertigoEffect.cs` |
| `WindParticle` | Height-aware wind debris particle with soft-particle depth fade |
| `ProceduralRustPBR` | Full PBR shader with procedural rust, scratches, and safety stripe — no texture files needed |

---

### 💻 Scripts — 10 C# Unity scripts

| Script | Attach To | Description |
|---|---|---|
| `WindSystem.cs` | Scene Manager | Master wind controller — gust scheduling, particle emission, global shader properties |
| `VertigoEffect.cs` | Main Camera | Downward-gaze detection driving chromatic aberration, FOV reduction, and post-process intensity |
| `StaminaSystem.cs` | Player | Stamina drain/regen with breathing audio feedback and UI slider |
| `GrabSystem.cs` | VR Controller | Surface detection, grab audio (metal/wood), haptic feedback, stamina integration |
| `HeightTracker.cs` | Player | Tracks world-space altitude, fires milestone events, broadcasts height factor |
| `BreakableProp.cs` | Pipe / Plank | Durability-based shake and break — damage accumulates per step or grab |
| `CollectibleSystem.cs` | Scene Manager | Toolbox collectible tracking with bob/rotate animation and collect events |
| `AmbientSoundManager.cs` | Scene Manager | Unified ambient audio — drone, gust, creak, distant construction |
| `CraneController.cs` | Crane Root | Trolley back-and-forth movement with payload swing integration |
| `VertigoTriggerZone.cs` | Trigger Collider | Placement-based vertigo boost — use on narrow planks and open edges |

---

## ⚙️ Unity Setup

### Requirements

- Unity **2022.3 LTS** or later
- **Universal Render Pipeline (URP)**
- XR Interaction Toolkit `2.x`
- Meta XR SDK (for haptics on Quest)

### Importing 3D Models

1. Copy `.obj` + `.mtl` into the **same folder** under `Assets/`
2. Drag the `.obj` into the Project window
3. In the Inspector → **Model** tab:
   - Scale Factor: `0.1`
   - Generate Colliders: `OFF`
   - Mesh Compression: `Medium`
4. Unity auto-generates materials from the `.mtl` — no textures needed

### Recommended Material Tweaks (URP Lit)

| Surface type | Smoothness |
|---|---|
| Rusty steel / rebar | 0.10 – 0.20 |
| Painted crane steel | 0.30 – 0.45 |
| Concrete / wood | 0.05 – 0.15 |
| Cable / wire | 0.35 |
| Glass panel | 0.75 |

### Importing Audio

1. Copy `.wav` files to `Assets/Audio/`
2. Select all → Inspector:
   - Load Type: `Compressed In Memory`
   - Compression Format: `Vorbis`
   - Quality: `70`
   - Sample Rate Setting: `Preserve Sample Rate`
3. For loop files (`wind_drone_loop`, `breathing_heavy_loop`): enable **Loop** on the AudioSource

### Shader Setup

| Shader | Usage |
|---|---|
| `OvercastSky` | Lighting → Environment → Skybox Material |
| `VolumetricFog` | URP Renderer Feature → Full Screen Pass (add to ForwardRenderer asset) |
| `VertigoPostProcess` | URP Renderer Feature → Full Screen Pass, assign Material to `VertigoEffect.cs` |
| `WindParticle` | Assign to Particle System Material slot |
| `ProceduralRustPBR` | Assign to any scaffolding or pipe Material |

### Script Wiring

```
Scene hierarchy example:

[SceneManager]
  ├── WindSystem.cs          ← assign PlayerTransform, WindParticles, AudioSources
  ├── AmbientSoundManager.cs ← assign all AudioSources and clips
  ├── HeightTracker.cs       ← assign PlayerHead transform
  └── CollectibleSystem.cs   ← assign PlayerHand transform

[XR Rig]
  └── Camera Offset
        └── Main Camera
              ├── VertigoEffect.cs   ← assign PPVolume and VertigoMaterial
              └── StaminaSystem.cs   ← assign AudioSource and UI Slider

[Crane]
  ├── CraneController.cs     ← assign Trolley, CranePayloadSwing
  └── Payload
        └── CranePayloadSwing.cs (from previous asset pack)
```

---

## 🎮 VR Performance Notes (Meta Quest 2 / 3)

- All models stay **under 3,500 triangles** per asset
- Crane is the heaviest at 1,796 tris — keep to **1 instance per scene**
- Enable **Static Batching** on all non-moving props
- `ProceduralRustPBR.shader` uses a 5-octave FBM loop — limit to **20 simultaneous instances** on Quest 2
- `VolumetricFog.shader` uses raymarching — set **Max Ray Steps** low (8–12) for Quest
- Target: **72 Hz** fixed foveated rendering, draw calls **< 80** per eye

---

## 🤝 Contributing

When adding assets, follow these conventions:

| Rule | Detail |
|---|---|
| Format | `.obj` + `.mtl` only — no external PNG textures |
| Naming | `snake_case` (e.g. `steel_door_frame`) |
| Origin | Base center at `(0, 0, 0)` |
| Scale | 1 unit = 1 metre inside the OBJ |
| Poly limit | Under `5,000` triangles per asset |
| Materials | Minimum 2 named materials in the `.mtl` |
| Audio | 44100 Hz / 16-bit / Mono WAV |
| Scripts | One class per `.cs` file, same filename as class |

### Commit Convention

```
feat:   add new asset, shader, audio, or script
fix:    correct geometry, shader bug, or script logic error
opt:    reduce polygon count or improve VR performance
refac:  rename, restructure, or reorganize without behavior change
docs:   update README or inline comments
audio:  add or modify WAV files
shader: add or modify .shader files
```

---

## 📋 License

Assets, audio, shaders, and scripts created for the **Vertigo Vault** academic project.  
For team use only — do not redistribute externally without permission.
