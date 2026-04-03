# Remotion API Reference

Complete reference for Remotion animation APIs.

## Hooks

### useCurrentFrame()
Returns the current frame number (0-indexed).

```tsx
const frame = useCurrentFrame();
console.log(frame); // 0, 1, 2, 3, ...
```

### useVideoConfig()
Returns composition configuration.

```tsx
const { width, height, fps, durationInFrames, id } = useVideoConfig();
```

## Animation Functions

### interpolate()
Maps a value from one range to another with optional easing.

```tsx
// Basic
const opacity = interpolate(frame, [0, 30], [0, 1]);

// With easing
const x = interpolate(frame, [0, 100], [0, 500], {
  extrapolateLeft: 'clamp',
  extrapolateRight: 'clamp',
  easing: Easing.bezier(0.4, 0, 0.2, 1),
});

// Multiple stops
const scale = interpolate(frame, [0, 30, 60, 90], [0.5, 1, 1, 0.5], {
  extrapolateLeft: 'clamp',
  extrapolateRight: 'clamp',
});
```

**Options:**
- `extrapolateLeft`: 'extend' | 'clamp' | 'wrap' | 'identity'
- `extrapolateRight`: 'extend' | 'clamp' | 'wrap' | 'identity'
- `easing`: Easing function

### spring()
Creates physics-based spring animation.

```tsx
const scale = spring({
  fps,                    // Frame rate
  frame,                 // Current frame
  config: {
    damping: 10,         // Deceleration (higher = smoother)
    mass: 1,             // Weight (higher = bouncier)
    stiffness: 100,      // Bounciness (higher = snappier)
  },
  durationInFrames: 40,  // Optional: stretch to fixed duration
  delay: 10,             // Optional: delay start
});
```

**When to use spring vs interpolate:**
- `spring()` - Natural, physics-based motion (bouncing, elastic)
- `interpolate()` - Precise, controlled transitions (fade, slide)

## Easing Functions

### Built-in Easings
```tsx
import { Easing } from 'remotion';

Easing.linear
Easing.ease
Easing.in(Easing.ease)
Easing.out(Easing.ease)
Easing.inOut(Easing.ease)
```

### Advanced Easings
```tsx
Easing.bounce
Easing.elastic(1)     // 0-1 intensity
Easing.back(0.5)     // 0-1 overshoot amount
Easing.cubic
Easing.sin
Easing.circle
Easing.exp
```

### Bezier Curves
```tsx
// CSS-like bezier curves
Easing.bezier(0.4, 0, 0.2, 1)  // ease-out
Easing.bezier(0.68, -0.55, 0.27, 1.55)  // back
```

## Components

### AbsoluteFill
Full-screen container (100% width/height).

```tsx
import { AbsoluteFill } from 'remotion';

<AbsoluteFill style={{ backgroundColor: 'black' }}>
  <h1>Content</h1>
</AbsoluteFill>
```

### Sequence
Time-based sub-composition.

```tsx
import { Sequence } from 'remotion';

<Sequence from={30} durationInFrames={60}>
  <MyComponent />
</Sequence>

// Or with name
<Sequence from={0} name="Intro">
  <IntroSequence />
</Sequence>
```

### Audio
Add audio to composition.

```tsx
<Audio src="https://example.com/music.mp3" />
<Audio src={staticFile('music.mp3')} />

// With options
<Audio
  src={staticFile('music.mp3')}
  volume={0.5}
  playbackRate={1}
/>
```

### Video
Embed video.

```tsx
<Video src={staticFile('background.mp4')} />
<Video src="https://example.com/video.mp4" />
```

### Img
Optimized image component.

```tsx
<Img src={staticFile('image.png')} />
```

### OffthreadVideo
Video rendered off-thread (better performance).

```tsx
<OffthreadVideo src={staticFile('video.mp4')} />
```

## Helpers

### staticFile()
Reference files in public/ folder.

```tsx
import { staticFile } from 'remotion';

<Audio src={staticFile('music.mp3')} />
<Img src={staticFile('image.png')} />
```

### getInputProps()
Access CLI input props.

```bash
npx remotion render MyVideo out.mp4 --props='{"text":"Hello"}'
```

```tsx
import { getInputProps } from 'remotion';

const { text } = getInputProps();
```

## Animation Patterns

### Delayed Animation
```tsx
const delayedFrame = Math.max(0, frame - 20);
const value = spring({ fps, frame: delayedFrame });
```

### Loop Animation
```tsx
const loopFrame = frame % 60;
const value = spring({ fps, frame: loopFrame });
```

### Reverse Animation
```tsx
const reverseFrame = durationInFrames - frame;
const value = spring({ fps, frame: reverseFrame });
```

### Shake Effect
```tsx
const shake = Math.sin(frame * 0.5) * 5;
const x = interpolate(frame, [0, 30], [0, shake]);
```

### Pulse Effect
```tsx
const pulse = interpolate(
  Math.sin(frame * 0.1),
  [-1, 1],
  [0.8, 1.2]
);
```

### Color Cycle
```tsx
const colors = ['#ff0000', '#00ff00', '#0000ff'];
const colorIndex = Math.floor(frame / 30) % colors.length;
const color = colors[colorIndex];
```

### Float Animation
```tsx
const floatY = interpolate(
  frame,
  [0, 60, 120],
  [0, -20, 0],
  { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }
);
```

### Fade In/Out
```tsx
const opacity = interpolate(
  frame,
  [0, 30, 120, 150],
  [0, 1, 1, 0],
  { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }
);
```

### Scale Pop
```tsx
const scale = spring({
  fps,
  frame,
  config: { damping: 8, stiffness: 200 }
});
```

## Advanced

### Custom Easing with Keyframes
```tsx
const progress = interpolate(frame, [0, 30, 60], [0, 0.5, 1], {
  extrapolateLeft: 'clamp',
  extrapolateRight: 'clamp',
  easing: Easing.bezier(0.2, 0.8, 0.4, 1),
});
```

### Combine Animations
```tsx
const scale = spring({ fps, frame, config: { damping: 10 } });
const opacity = interpolate(frame, [0, 30], [0, 1]);

return (
  <div style={{
    transform: `scale(${scale})`,
    opacity
  }}>
    Content
  </div>
);
```

### Staggered Animations
```tsx
const delays = [0, 10, 20, 30];
const elements = delays.map((delay, i) => {
  const delayedFrame = Math.max(0, frame - delay);
  const scale = spring({ fps, frame: delayedFrame, config: { damping: 10 } });
  return <div key={i} style={{ transform: `scale(${scale})` }} />;
});
```

## Useful Resources

- [Remotion Docs](https://www.remotion.dev/docs)
- [Spring Animation Editor](https://www.remotion.dev/timing-editor)
- [Easing Functions](https://easings.net/)
- [Cubic Bezier Tool](https://cubic-bezier.com/)