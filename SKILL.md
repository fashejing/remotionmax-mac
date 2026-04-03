---
name: remotionmax-mac
description: >
  Create Remotion animations for Mac - one click to create, edit, and preview.
  Supports batch mode for creating multiple animations at once, opening all in ONE Cursor workspace.
  Use when user wants to create animated videos with Remotion, especially multiple animations at once.
  Triggers on: create animation, remotion preview, open video editor, start remotion, animation studio, batch animations.
---

# RemotionMAX-Mac - Animation Studio

One-click Remotion animation studio, Mac optimized. Create single or multiple animations efficiently.

## What is RemotionMAX-Mac?

RemotionMAX-Mac combines three steps into one:
1. **Create** - Generate animation project with dependencies
2. **Open** - Launch in Cursor (single workspace for batch)
3. **Preview** - Start live preview server (single browser tab)

## Usage

### Single Animation
```bash
bash ~/.agents/skills/remotionmax-mac/scripts/launch.sh \
  --name "my-animation" \
  --theme "neon glow logo" \
  --editor "cursor" \
  --auto
```

### Batch Mode (Multiple Animations)
Create multiple animations, then launch all at once in ONE Cursor window:

```bash
# Step 1: Create projects (batch mode - won't open cursor/browser)
bash ~/.agents/skills/remotionmax-mac/scripts/launch.sh --name "project-1" --theme "neon" --auto --batch
bash ~/.agents/skills/remotionmax-mac/scripts/launch.sh --name "project-2" --theme "pixel" --auto --batch
bash ~/.agents/skills/remotionmax-mac/scripts/launch.sh --name "project-3" --theme "cyberpunk" --auto --batch

# Step 2: Launch all projects at once
bash ~/.agents/skills/remotionmax-mac/scripts/launch.sh --launch
```

### Batch Mode Benefits
- **ONE Cursor window** with all project folders
- **ONE preview terminal** with all servers running
- **ONE browser tab** showing first preview
- All animations ready simultaneously

## Command Line Options

| Option | Description |
|:-------|:------------|
| `--name` | Project name |
| `--theme` | Animation theme/description |
| `--editor` | `cursor` or `vscode` |
| `--template` | `blank`, `hello-world`, `three-fiber`, `still-images` |
| `--path` | Custom project path |
| `--port` | Preview port (default: 3456) |
| `--batch` | Add to batch queue, don't open yet |
| `--launch` | Launch all batched projects |
| `--auto` | Skip all prompts, use defaults |

## Animation Themes

| Theme Type | Examples |
|:---|:---|
| **Logo Animations** | Neon glow, pixel morph, rainbow glitch |
| **Text Effects** | Wave text, holographic, color wave |
| **Particles** | Fireworks, floating orbs, star field |
| **Abstract** | Geometric shapes, morphing blobs |
| **Retro** | 8-bit pixel art, arcade style |
| **Futuristic** | Cyberpunk, holographic, sci-fi HUD |

## Workflow

### Single Animation
```
1. Run script with options
       ↓
2. Project created & dependencies installed
       ↓
3. Cursor opens with project
       ↓
4. Preview server starts
       ↓
5. Browser opens with animation
```

### Batch Mode (Multiple Animations)
```
1. Run script with --batch (multiple times)
       ↓
2. All projects created (no windows open)
       ↓
3. Run with --launch
       ↓
4. ONE Cursor opens with ALL folders
       ↓
5. All preview servers start
       ↓
6. Browser opens with first preview
```

## Core Remotion APIs

See [references/remotion-api.md](references/remotion-api.md) for complete API reference.

### useCurrentFrame()
```tsx
const frame = useCurrentFrame();
```

### interpolate()
```tsx
const opacity = interpolate(frame, [0, 30], [0, 1]);
```

### spring()
```tsx
const scale = spring({ fps, frame, config: { damping: 10 } });
```

## After Launch

### Preview
- http://localhost:3456 (or specified port)
- Real-time editing - changes update instantly
- Use Remotion Studio to switch between compositions

### Render
```bash
# MP4
npx remotion render ThemeAnimation out.mp4

# GIF
npx remotion render ThemeAnimation out.gif --codec=gif
```

## Tips

- **Batch creation**: Use `--batch` for creating many animations efficiently
- **Workspace**: All batched projects open in single Cursor window
- **Multiple previews**: Preview servers run on different ports (3456, 3457, etc.)
- **Edit anytime**: Run `--launch` again if you need to reopen all projects

## Resources

- [Remotion Docs](https://www.remotion.dev/docs)
- [Spring Animation](https://www.remotion.dev/docs/spring)
- [Easing Functions](https://easings.net/)
