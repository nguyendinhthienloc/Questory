# Questory demo user flow

The release demo starts with Questory rather than the inherited camera screen.
It uses a completed offline run fixture so Story Studio can be demonstrated even
when GPS, camera hardware, or another team module is unavailable.

```mermaid
flowchart TD
    A[Launch Questory] --> B[Explore]
    B --> C[Open completed Nha Trang run]
    C --> D[Run recap]
    D --> E[Review route, metrics, quests, and photo evidence]
    E --> F[Create story]
    F --> G[Story Studio]
    G --> H[Choose a template]
    H --> I[Edit text, photos, crop, colors, transforms, and layers]
    I --> J[Save editable draft]
    I --> K[Export 1080 x 1920 PNG]
    K --> L{Platform}
    L -->|Edge or web| M[Download PNG]
    L -->|Android| N[Open Android share sheet]
    B --> O[Studio tab]
    O --> G
    B --> P[Runs tab]
    P --> D
    J --> O
```

## Demo boundary

- Explore, Runs, and Run recap are fixture-driven navigation surfaces.
- Story Studio, document editing, save/reopen, rendering, and export are the
  real Story Studio implementation.
- The app-scoped fake repository acts as the mock backend for the current app
  session and returns cloned serialized documents.
- Edge DevTools does not emulate camera hardware. The demo run already contains
  deterministic quest evidence, so camera availability never blocks the Story
  Studio demonstration.
- Real camera evidence, GPS tracking, durable storage, and release navigation
  remain replaceable integration adapters owned by their respective modules.
