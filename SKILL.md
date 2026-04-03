---
name: remotionmax-mac
description: >
  Create Remotion animations for Mac - one click to create, edit, and preview.
  Supports batch mode for creating multiple animations in ONE project, switchable in Remotion Studio.
  Default editor is VS Code.
  Triggers on: create animation, remotion preview, open video editor, start remotion, animation studio, batch animations.
---

# RemotionMAX-Mac - Animation Studio

One-click Remotion animation studio, Mac optimized. Create single or multiple animations efficiently.

## What is RemotionMAX-Mac?

RemotionMAX-Mac combines three steps into one:
1. **Create** - Generate animation project with dependencies
2. **Open** - Launch in VS Code
3. **Preview** - Start live preview server

## Usage

### Single Animation
```bash
bash ~/.agents/skills/remotionmax-mac/scripts/launch.sh \
  --name "my-animation" \
  --theme "neon glow logo" \
  --auto
```

### Batch Mode (Multiple Animations in ONE Project)
Create multiple animations that go into ONE project. Switch between them in Remotion Studio:

```bash
# Step 1: Create project with first animation
bash ~/.agents/skills/remotionmax-mac/scripts/launch.sh --name "my-batch" --theme "neon" --auto --batch

# Step 2: Add more animations to the same project
bash ~/.agents/skills/remotionmax-mac/scripts/launch.sh --name "my-batch" --theme "pixel" --auto --batch
bash ~/.agents/skills/remotionmax-mac/scripts/launch.sh --name "my-batch" --theme "cyberpunk" --auto --batch

# Step 3: Launch when done
bash ~/.agents/skills/remotionmax-mac/scripts/launch.sh --launch
```

### Batch Mode Benefits
- **ONE project** with all animations
- **ONE VS Code window**
- **ONE preview server** - switch animations in Remotion Studio
- All animations in one place, easy to manage

## Command Line Options

| Option | Description |
|:-------|:------------|
| `--name` | Project name (same name adds to existing batch project) |
| `--theme` | Animation theme/description |
| `--editor` | `vscode` (default) or `cursor` |
| `--template` | `blank`, `hello-world`, `three-fiber`, `still-images` |
| `--path` | Custom project path |
| `--port` | Preview port (default: 3456) |
| `--batch` | Add animation to batch project (same project name = same project) |
| `--launch` | Launch batch project |
| `--force` | Kill all existing preview servers before starting |
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
3. VS Code opens with project
       ↓
4. Preview server starts
       ↓
5. Browser opens with animation
```

### Batch Mode (Multiple Animations)
```
1. First --batch creates project + Animation01
       ↓
2. Second --batch adds Animation02 to same project
       ↓
3. Third --batch adds Animation03, etc.
       ↓
4. Run --launch
       ↓
5. VS Code opens with ONE project
       ↓
6. ONE preview server starts
       ↓
7. Browser opens - use Remotion Studio to switch animations
```

## Switching Animations in Remotion Studio

After launching:
1. Open http://localhost:3456 in browser
2. Click the Remotion Studio logo (top-left)
3. Select different animations from the dropdown
4. All animations are in the same project!

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
- Click Remotion Studio logo to switch between animations

### Render
```bash
# Render specific animation
npx remotion render Animation01 out.mp4

# GIF
npx remotion render Animation01 out.gif --codec=gif
```

## Tips

- **Batch by name**: Use same `--name` to add animations to the same project
- **Switch in Studio**: All animations accessible via Remotion Studio dropdown
- **One project**: All batch animations live in `src/Animation01.tsx`, `Animation02.tsx`, etc.
- **Edit anytime**: Run `--launch` again to reopen

## Resources

- [Remotion Docs](https://www.remotion.dev/docs)
- [Spring Animation](https://www.remotion.dev/docs/spring)
- [Easing Functions](https://easings.net/)
