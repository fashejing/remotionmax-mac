#!/bin/bash
# remotionmax-mac - One-click animation studio (Mac optimized)
# Creates animation, opens editor, starts preview
# Supports batch mode for creating multiple animations at once
# All animations open in ONE Cursor workspace, ONE preview terminal

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME=""
THEME=""
EDITOR=""
TEMPLATE="hello-world"
PROJECT_PATH="/Users/fsj/Documents/emowowo remotion"
PORT=3456
AUTO_MODE=false
MAX_RETRIES=5
BATCH_MODE=false
LAUNCH_MODE=false
DEFER_OPEN=false
FORCE_CLEAN=false
BATCH_FILE="$HOME/.remotionmax-batch.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --name)
      PROJECT_NAME="$2"
      shift 2
      ;;
    --theme)
      THEME="$2"
      shift 2
      ;;
    --editor)
      EDITOR="$2"
      shift 2
      ;;
    --template)
      TEMPLATE="$2"
      shift 2
      ;;
    --path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --auto|--yes)
      AUTO_MODE=true
      shift
      ;;
    --batch)
      BATCH_MODE=true
      DEFER_OPEN=true
      shift
      ;;
    --launch)
      LAUNCH_MODE=true
      shift
      ;;
    --defer-open)
      DEFER_OPEN=true
      shift
      ;;
    --force)
      FORCE_CLEAN=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Banner
echo -e "${CYAN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ██████╗██████╗ ██╗   ██╗██████╗ ████████╗ ██████╗  ██████╗ ██████╗ ██╗   ██╗"
echo " ██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝██╔═══██╗██╔═══██╗██╔══██╗╚██╗ ██╔╝"
echo " ██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║   ██║   ██║██║   ██║██████╔╝ ╚████╔╝ "
echo " ██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║   ██║   ██║██║   ██║██╔══██╗  ╚██╔╝  "
echo " ╚██████╗██║  ██║   ██║   ██║        ██║   ╚██████╔╝╚██████╔╝██║  ██╗   ██║   "
echo "  ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝    ╚═════╝  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   "
echo "                                       MAX-MAC"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"

# Launch mode - open batch project with all animations
if [ "$LAUNCH_MODE" = true ]; then
  echo -e "${YELLOW}🚀 Launching batch project...${NC}"
  echo ""

  if [ ! -f "$BATCH_FILE" ]; then
    echo -e "${RED}❌ No batch file found. Create project first with --batch flag.${NC}"
    exit 1
  fi

  # Read batch file (new format: {projectPath, port, animations[]})
  BATCH_DATA=$(cat "$BATCH_FILE")
  PROJECT_PATH=$(echo "$BATCH_DATA" | jq -r '.projectPath')
  PORT=$(echo "$BATCH_DATA" | jq -r '.port')
  ANIMATIONS=$(echo "$BATCH_DATA" | jq -r '.animations | join(", ")')
  ANIMATION_COUNT=$(echo "$BATCH_DATA" | jq -r '.animations | length')

  if [ -z "$PROJECT_PATH" ] || [ "$PROJECT_PATH" = "null" ]; then
    echo -e "${RED}❌ Invalid batch file.${NC}"
    exit 1
  fi

  echo -e "${GREEN}📦 Found batch project with $ANIMATION_COUNT animations${NC}"
  echo ""
  echo -e "${BLUE}   Project: $(basename "$PROJECT_PATH")"
  echo "   Animations: $ANIMATIONS"
  echo "   Port: $PORT${NC}"
  echo ""

  # Kill any existing remotion preview processes
  echo -e "${YELLOW}🔪 Cleaning up existing preview servers...${NC}"
  pkill -f "remotion preview" 2>/dev/null || true
  sleep 2

  # Kill port function
  kill_port() {
    local p=$1
    lsof -ti :$p | xargs kill -9 2>/dev/null || true
    sleep 1
  }

  # Kill any process on the port
  echo -e "${YELLOW}   Killing process on port $PORT...${NC}"
  kill_port $PORT
  sleep 1

  # Open VS Code with project
  echo -e "${GREEN}💻 Opening VS Code with project...${NC}"
  code "$PROJECT_PATH" &
  sleep 2

  # Start preview server
  echo -e "${GREEN}🚀 Starting preview server...${NC}"
  cd "$PROJECT_PATH"
  nohup npx remotion preview --port $PORT > /tmp/remotionmax-$PORT.log 2>&1 &
  sleep 8

  # Wait for server to be ready
  echo -e "${BLUE}⏳ Waiting for preview to compile...${NC}"
  for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT" 2>/dev/null | grep -q "200"; then
      echo -e "${GREEN}✅ Preview ready!${NC}"
      break
    fi
    sleep 2
  done

  # Open browser
  echo -e "${GREEN}🌐 Opening preview in browser...${NC}"
  open "http://localhost:$PORT"

  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}✅ Batch Project Ready!${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "   ${PURPLE}📁 Project:${NC} $(basename "$PROJECT_PATH")"
  echo -e "   ${PURPLE}🎬 Animations:${NC} $ANIMATION_COUNT ($ANIMATIONS)"
  echo -e "   ${PURPLE}🔗 Preview:${NC} http://localhost:$PORT"
  echo ""
  echo -e "${YELLOW}   Switch between animations in Remotion Studio!${NC}"
  echo ""

  # Clean up batch file
  rm -f "$BATCH_FILE"

  exit 0
fi

echo -e "${YELLOW}One-click Animation Studio (Mac Optimized)${NC}"
echo ""

# Interactive mode
if [ "$AUTO_MODE" = false ]; then
  echo -e "${BLUE}📝 Step 1: Project Details${NC}"
  
  # Get project name
  if [ -z "$PROJECT_NAME" ]; then
    echo -n "   Enter project name (default: my-animation): "
    read -r PROJECT_NAME
    [ -z "$PROJECT_NAME" ] && PROJECT_NAME="my-animation"
  fi

  # Get theme
  if [ -z "$THEME" ]; then
    echo ""
    echo -e "${BLUE}🎨 Step 2: Animation Theme${NC}"
    echo "   What kind of animation do you want?"
    echo "   Examples:"
    echo "   - 'neon glow logo'"
    echo "   - 'particle explosion'"
    echo "   - 'rainbow text wave'"
    echo "   - 'cyberpunk glitch'"
    echo "   - 'pixel art character'"
    echo ""
    echo -n "   Enter your animation theme: "
    read -r THEME
    [ -z "$THEME" ] && THEME="neon glow logo"
  fi

  # Get editor choice
  if [ -z "$EDITOR" ]; then
    echo ""
    echo -e "${BLUE}💻 Step 3: Choose Editor${NC}"
    echo "   1) Cursor (recommended)"
    echo "   2) VS Code"
    echo ""
    echo -n "   Select editor (1 or 2): "
    read -r EDITOR_CHOICE
    case $EDITOR_CHOICE in
      2) EDITOR="vscode" ;;
      *) EDITOR="vscode" ;;
    esac
  fi

  # Get template
  echo ""
  echo -e "${BLUE}📋 Step 4: Choose Template${NC}"
  echo "   1) hello-world (simple animation)"
  echo "   2) blank (empty canvas)"
  echo "   3) three-fiber (3D animations)"
  echo "   4) still-images (dynamic images)"
  echo ""
  echo -n "   Select template (default: 1): "
  read -r TEMPLATE_CHOICE
  case $TEMPLATE_CHOICE in
    2) TEMPLATE="blank" ;;
    3) TEMPLATE="three-fiber" ;;
    4) TEMPLATE="still-images" ;;
    *) TEMPLATE="hello-world" ;;
  esac
fi

# Set defaults if still empty
[ -z "$PROJECT_NAME" ] && PROJECT_NAME="my-animation"
[ -z "$THEME" ] && THEME="neon glow logo"
[ -z "$EDITOR" ] && EDITOR="vscode"
[ -z "$PROJECT_PATH" ] && PROJECT_PATH="/Users/fsj/Documents/emowowo remotion"

FULL_PATH="$PROJECT_PATH/$PROJECT_NAME"

# Check for batch mode FIRST - before any project creation
if [ "$BATCH_MODE" = true ] && [ -f "$BATCH_FILE" ]; then
  # Batch file exists - check if this project already has an entry
  BATCH_DATA=$(cat "$BATCH_FILE")
  BATCH_PROJECT_PATH=$(echo "$BATCH_DATA" | jq -r '.projectPath')

  if [ "$FULL_PATH" = "$BATCH_PROJECT_PATH" ]; then
    # Same project - just add animation
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}📦 Adding animation to existing batch project...${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "   Project: $PROJECT_NAME"
    echo "   Theme: $THEME"
    echo ""

    ANIMATION_COUNT=$(echo "$BATCH_DATA" | jq -r '.animations | length')
    NEW_ANIMATION_NAME="Animation$(printf '%02d' $((ANIMATION_COUNT + 1)))"

    # Create animation file with AI-generated content
    generate_ai_animation "$THEME" "$FULL_PATH/src/${NEW_ANIMATION_NAME}.tsx" "$NEW_ANIMATION_NAME"

    # Update index.tsx to register new animation
    ANIMATIONS_JSON=$(echo "$BATCH_DATA" | jq -r '.animations | map({id: ., component: ., duration: 150})')
    NEW_ANIM_ID=$(basename "$NEW_ANIMATION_NAME" .tsx)

    # Create updated index.tsx
    cat > "$FULL_PATH/src/index.tsx" << INDEXEOF
import { Composition, registerRoot } from 'remotion';
import React from 'react';
$(echo "$BATCH_DATA" | jq -r '.animations[]' | while read anim; do
  echo "import $anim from './$anim';"
done)

const compositions = [
$(echo "$BATCH_DATA" | jq -r '.animations[]' | while read anim; do
  echo "  { id: '$anim', component: $anim, duration: 150 },"
done)
  { id: '$NEW_ANIMATION_NAME', component: require('./$NEW_ANIMATION_NAME').default, duration: 150 },
];

const Root: React.FC = () => {
  return (
    <>
      {compositions.map((comp) => (
        <Composition
          key={comp.id}
          id={comp.id}
          component={comp.component}
          durationInFrames={comp.duration}
          fps={30}
          width={1920}
          height={1080}
        />
      ))}
    </>
  );
};

registerRoot(Root);
INDEXEOF

    # Update batch file
    echo "$BATCH_DATA" | jq ".animations += [\"$NEW_ANIMATION_NAME\"]" > "$BATCH_FILE"

    echo -e "${GREEN}✅ Animation added to batch project${NC}"
    echo ""
    echo -e "${BLUE}   Animation: $NEW_ANIMATION_NAME"
    echo "   Project: $(basename "$FULL_PATH")"
    echo "   Total animations: $((ANIMATION_COUNT + 1))${NC}"
    echo ""
    exit 0
  fi
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📦 Creating your animation project...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "   Project: $PROJECT_NAME"
echo "   Theme: $THEME"
echo "   Editor: $EDITOR"
echo "   Template: $TEMPLATE"
echo "   Path: $FULL_PATH"
echo ""

# Check if directory exists
if [ -d "$FULL_PATH" ]; then
  echo -e "${YELLOW}⚠️  Directory exists. Removing old project...${NC}"
  rm -rf "$FULL_PATH"
fi

# Create project structure
echo -e "${GREEN}📁 Creating project structure...${NC}"
mkdir -p "$FULL_PATH"/{src,public}

# Create package.json
cat > "$FULL_PATH/package.json" << 'PKGEOF'
{
  "name": "remotion-project",
  "version": "1.0.0",
  "description": "Created with RemotionMAX-Mac",
  "scripts": {
    "start": "remotion preview",
    "build": "remotion render MyVideo out.mp4",
    "preview": "remotion preview"
  },
  "dependencies": {
    "@remotion/cli": "^4.0.0",
    "@remotion/bundler": "^4.0.0",
    "remotion": "^4.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  }
}
PKGEOF

# Create tsconfig.json
cat > "$FULL_PATH/tsconfig.json" << 'TSEOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020", "DOM"],
    "jsx": "react-jsx",
    "strict": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"]
}
 TSEOF

# Function to generate animation code using AI
generate_ai_animation() {
  local theme="$1"
  local output_file="$2"
  local anim_name="$3"

  echo -e "${CYAN}🤖 AI is creating unique animation based on your theme...${NC}"
  echo -e "${BLUE}   Theme: $theme${NC}"
  echo ""

  # Check for OpenAI API key
  if [ -n "$OPENAI_API_KEY" ]; then
    generate_with_openai "$theme" "$output_file" "$anim_name"
  elif [ -n "$ANTHROPIC_API_KEY" ]; then
    generate_with_claude "$theme" "$output_file" "$anim_name"
  else
    echo -e "${YELLOW}⚠️  No AI API key found, using creative default animation${NC}"
    generate_creative_default "$output_file" "$anim_name"
  fi
}

# Generate animation with OpenAI
generate_with_openai() {
  local theme="$1"
  local output_file="$2"
  local anim_name="$3"

  local prompt="Create a premium Remotion animation for the word 'EMOWOWO' with the theme: $theme

Requirements:
- Use React with remotion hooks: useCurrentFrame, interpolate, spring, Easing, AbsoluteFill
- Pure CSS/JS animations (no external assets)
- Unique, creative visual effects that match the theme
- Export as default component
- Frame rate: 30fps
- Duration: 150 frames (5 seconds)
- Resolution: 1920x1080

Create ONLY the TSX file content with:
1. Imports from 'remotion' and 'react'
2. The main component using useCurrentFrame() hook
3. Animations using spring() and interpolate() 
4. Unique visual effects based on the theme
5. Default export

Write creative, professional-quality animation code that showcases the theme. Make it visually impressive and unique."

  local response=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "{\"model\": \"gpt-4o\", \"messages\": [{\"role\": \"user\", \"content\": $prompt}], \"temperature\": 0.9}" 2>/dev/null)

  local content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)

  if [ -n "$content" ] && [ "$content" != "null" ]; then
    # Clean up markdown code blocks if present
    content=$(echo "$content" | sed 's/```tsx//g' | sed 's/```//g' | sed 's/^import/import/' | sed 's/^export/export/')
    echo "$content" > "$output_file"
    echo -e "${GREEN}✅ AI animation created successfully${NC}"
  else
    echo -e "${YELLOW}⚠️  AI generation failed, using creative default${NC}"
    generate_creative_default "$output_file" "$anim_name"
  fi
}

# Generate animation with Claude
generate_with_claude() {
  local theme="$1"
  local output_file="$2"
  local anim_name="$3"

  local prompt="Create a premium Remotion animation for the word 'EMOWOWO' with the theme: $theme

Requirements:
- Use React with remotion hooks: useCurrentFrame, interpolate, spring, Easing, AbsoluteFill
- Pure CSS/JS animations (no external assets)
- Unique, creative visual effects that match the theme
- Export as default component
- Frame rate: 30fps
- Duration: 150 frames (5 seconds)
- Resolution: 1920x1080

Create ONLY the TSX file content. Write creative, professional-quality animation code that showcases the theme."

  local response=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -d "{\"model\": \"claude-sonnet-4-20250514\", \"max_tokens\": 2000, \"messages\": [{\"role\": \"user\", \"content\": $prompt}]}" 2>/dev/null)

  local content=$(echo "$response" | jq -r '.content[0].text' 2>/dev/null)

  if [ -n "$content" ] && [ "$content" != "null" ]; then
    content=$(echo "$content" | sed 's/```tsx//g' | sed 's/```//g' | sed 's/^import/import/' | sed 's/^export/export/')
    echo "$content" > "$output_file"
    echo -e "${GREEN}✅ AI animation created successfully${NC}"
  else
    echo -e "${YELLOW}⚠️  AI generation failed, using creative default${NC}"
    generate_creative_default "$output_file" "$anim_name"
  fi
}

# Creative default animation based on theme
generate_creative_default() {
  local output_file="$1"
  local anim_name="$2"

  # Generate animation based on theme keywords
  local theme_lower=$(echo "$THEME" | tr '[:upper:]' '[:lower:]')

  # Determine animation style based on theme
  if echo "$theme_lower" | grep -qi "pixel\|8-bit\|retro\|arcade"; then
    cat > "$output_file" << 'PIXELEOF'
import React from 'react';
import { useCurrentFrame, interpolate, spring, Easing, AbsoluteFill } from 'remotion';

const Animation: React.FC = () => {
  const frame = useCurrentFrame();
  const fps = 30;
  
  const scale = spring({ fps, frame, config: { damping: 10, stiffness: 80 } });
  const pixelSize = 8;
  const letters = ['E','M','O','W','O','W','O'];
  
  const letterPixels = [
    [[1,1,1,0,1,1,1],[1,0,1,0,1,0,1],[1,1,1,0,1,1,1],[1,0,1,0,1,0,1],[1,0,1,0,1,0,1]],
    [[1,1,1,0,1,1,1],[1,0,1,0,1,0,1],[1,1,1,0,1,1,1],[1,0,1,0,1,0,1],[1,1,1,0,1,1,1]],
    [[1,0,0,0,0,0,1],[1,0,0,0,0,0,1],[1,1,1,1,1,1,1],[1,0,0,0,0,0,1],[1,0,0,0,0,0,1]],
    [[1,0,0,0,0,0,1],[1,0,0,0,0,0,1],[1,1,1,1,1,1,1],[1,0,0,0,0,0,1],[1,0,0,0,0,0,1]],
    [[1,1,1,0,1,1,1],[1,0,1,0,1,0,1],[1,1,1,0,1,1,1],[1,0,1,0,1,0,1],[1,1,1,0,1,1,1]],
    [[1,1,1,0,1,1,1],[1,0,1,0,1,0,1],[1,1,1,0,1,1,1],[1,0,1,0,1,0,1],[1,1,1,0,1,1,1]],
    [[1,0,0,0,0,0,1],[1,0,0,0,0,0,1],[1,1,1,1,1,1,1],[1,0,0,0,0,0,1],[1,0,0,0,0,0,1]],
  ];
  
  return (
    <AbsoluteFill style={{ backgroundColor: '#000', justifyContent: 'center', alignItems: 'center' }}>
      <div style={{ display: 'flex', gap: 16, transform: `scale(${scale})` }}>
        {letters.map((letter, li) => (
          <div key={li} style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {letterPixels[li].map((row, ri) =>
              row.map((pixel, ci) => (
                <div key={`${li}-${ri}-${ci}`} style={{
                  width: pixelSize,
                  height: pixelSize,
                  backgroundColor: pixel ? '#fff' : 'transparent',
                }} />
              ))
            )}
          </div>
        ))}
      </div>
    </AbsoluteFill>
  );
};

export default Animation;
PIXELEOF
  elif echo "$theme_lower" | grep -qi "flip\|solari\|board\|split-flap"; then
    cat > "$output_file" << 'FLIPEOF'
import React from 'react';
import { useCurrentFrame, interpolate, spring, Easing, AbsoluteFill } from 'remotion';

const FlipCard: React.FC<{ char: string; delay: number }> = ({ char, delay }) => {
  const frame = useCurrentFrame();
  const localFrame = Math.max(0, frame - delay);
  const rotateX = interpolate(localFrame, [0, 15, 30], [0, 90, 180], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
    easing: Easing.bezier(0.4, 0, 0.6, 1),
  });
  const showFront = rotateX < 90;
  const opacity = interpolate(localFrame, [0, 5, 25, 30], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
  });
  return (
    <div style={{ width: 60, height: 80, perspective: 300, position: 'relative' }}>
      <div style={{
        width: '100%', height: '100%', position: 'absolute', backfaceVisibility: 'hidden',
        transform: `rotateX(${rotateX}deg)`, transformStyle: 'preserve-3d',
        display: 'flex', justifyContent: 'center', alignItems: 'center',
        backgroundColor: showFront ? '#fff' : '#000', border: '2px solid #333',
        opacity,
      }}>
        <span style={{ fontSize: 48, fontWeight: 900, color: showFront ? '#000' : '#fff' }}>{char}</span>
      </div>
    </div>
  );
};

const Animation: React.FC = () => {
  const letters = ['E','M','O','W','O','W','O'];
  return (
    <AbsoluteFill style={{ backgroundColor: '#1a1a1a', justifyContent: 'center', alignItems: 'center' }}>
      <div style={{ display: 'flex', gap: 8 }}>
        {letters.map((letter, i) => <FlipCard key={i} char={letter} delay={i * 12} />)}
      </div>
    </AbsoluteFill>
  );
};

export default Animation;
FLIPEOF
  elif echo "$theme_lower" | grep -qi "neon\|glow\|light"; then
    cat > "$output_file" << 'NEONEOF'
import React from 'react';
import { useCurrentFrame, interpolate, spring, Easing, AbsoluteFill } from 'remotion';

const Animation: React.FC = () => {
  const frame = useCurrentFrame();
  const fps = 30;
  const scale = spring({ fps, frame, config: { damping: 10, stiffness: 60 } });
  const glowIntensity = interpolate(frame, [0, 30, 60, 90, 120, 150], [0.3, 1, 0.5, 1, 0.5, 0.3], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
  });
  const colorShift = interpolate(frame, [0, 150], [0, 360]);
  return (
    <AbsoluteFill style={{ backgroundColor: '#0a0a1a', justifyContent: 'center', alignItems: 'center' }}>
      <div style={{ transform: `scale(${scale})` }}>
        <div style={{
          fontSize: 140, fontWeight: 900, fontFamily: 'Arial Black, sans-serif',
          background: `linear-gradient(${colorShift}deg, #ff00ff, #00ffff, #ffff00, #ff00ff)`,
          backgroundSize: '200% 200%',
          WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
          filter: `drop-shadow(0 0 ${20 + glowIntensity * 40}px rgba(255,0,255,${glowIntensity}))`,
        }}>
          EMOWOWO
        </div>
      </div>
    </AbsoluteFill>
  );
};

export default Animation;
NEONEOF
  else
    # Default creative animation
    cat > "$output_file" << 'DEFAULTEOF'
import React from 'react';
import { useCurrentFrame, interpolate, spring, Easing, AbsoluteFill } from 'remotion';

const Animation: React.FC = () => {
  const frame = useCurrentFrame();
  const fps = 30;
  const mainSpring = spring({ fps, frame, config: { damping: 10, stiffness: 60, mass: 0.8 }, delay: 10 });
  const textReveal = interpolate(frame, [20, 60, 120, 150], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
  });
  const gradientShift = interpolate(frame, [0, 150], [0, 360]);
  const floatY = interpolate(frame, [0, 75, 150], [0, -15, 0], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
  });
  const scale = spring({ fps, frame, config: { damping: 8, stiffness: 80 }, delay: 15 });

  return (
    <AbsoluteFill style={{
      background: `linear-gradient(${gradientShift * 0.5}deg, #1a0a2e 0%, #16213e 50%, #0f0f23 100%)`,
      justifyContent: 'center', alignItems: 'center', overflow: 'hidden',
    }}>
      {/* Animated shapes */}
      <div style={{
        position: 'absolute', left: '20%', top: '30%', width: 200, height: 200, borderRadius: '50%',
        background: 'linear-gradient(135deg, #ff6b6b40, #feca5740)',
        transform: `rotate(${frame * 0.5}deg) scale(${mainSpring * 0.6})`,
        filter: 'blur(30px)',
      }} />
      <div style={{
        position: 'absolute', right: '25%', bottom: '25%', width: 250, height: 250, borderRadius: '40% 60% 70% 30%',
        background: 'linear-gradient(225deg, #48dbfb40, #ff9ff340)',
        transform: `rotate(${-frame * 0.3}deg) scale(${mainSpring * 0.7})`,
        filter: 'blur(40px)',
      }} />

      {/* Text */}
      <div style={{ transform: `translateY(${floatY}) scale(${scale})`, opacity: textReveal }}>
        <div style={{
          fontSize: 150, fontWeight: 900, letterSpacing: '-0.02em',
          fontFamily: "'SF Pro Display', -apple-system, sans-serif",
          background: `linear-gradient(${90 + gradientShift}deg, #fff 0%, #f8f8ff 20%, #feca57 40%, #ff6b6b 60%, #ff9ff3 80%, #fff 100%)`,
          backgroundSize: '200% 200%',
          WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
          filter: 'drop-shadow(0 0 30px rgba(254, 202, 87, 0.6))',
        }}>
          EMOWOWO
        </div>
        <div style={{
          fontSize: 18, fontWeight: 300, letterSpacing: '0.5em', textAlign: 'center', marginTop: 20,
          color: 'rgba(255,255,255,0.7)',
        }}>
          CREATIVE STUDIO
        </div>
      </div>
    </AbsoluteFill>
  );
};

export default Animation;
DEFAULTEOF
  fi
  echo -e "${GREEN}✅ Creative animation created based on theme${NC}"
}

# Batch mode first run: create Animation01 and save batch file
if [ "$BATCH_MODE" = true ] && [ ! -f "$BATCH_FILE" ]; then
  # Find available port
  TEST_PORT=$PORT
  while lsof -i :$TEST_PORT >/dev/null 2>&1; do
    TEST_PORT=$((TEST_PORT + 1))
  done

  echo -e "${GREEN}🎨 Creating batch animation for: $THEME${NC}"

  # Create Animation01.tsx with AI-generated or creative content
  generate_ai_animation "$THEME" "$FULL_PATH/src/Animation01.tsx" "Animation01"

  # Create index.tsx with Animation01 registration
  cat > "$FULL_PATH/src/index.tsx" << 'INDEXEOF'
import { Composition, registerRoot } from 'remotion';
import React from 'react';
import Animation01 from './Animation01';

const Root: React.FC = () => {
  return (
    <Composition
      id="Animation01"
      component={Animation01}
      durationInFrames={150}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};

registerRoot(Root);
INDEXEOF

  touch "$FULL_PATH/public/.gitkeep"

  # Save batch file
  echo "{\"projectPath\": \"$FULL_PATH\", \"port\": $TEST_PORT, \"animations\": [\"Animation01\"]}" > "$BATCH_FILE"

  echo -e "${GREEN}✅ Batch project created${NC}"
  echo ""
  echo -e "${BLUE}   Project: $PROJECT_NAME"
  echo "   Path: $FULL_PATH"
  echo "   Port: $TEST_PORT"
  echo "   Animations: 1${NC}"
  echo ""
  echo -e "${YELLOW}   Run --batch again with same --name to add more animations${NC}"
  echo "   Run --launch when done to open and preview${NC}"
  echo ""
  exit 0
fi

# Generate animation code based on theme
echo -e "${GREEN}🎨 Generating animation code for: $THEME${NC}"

# Create a clean animation file
cat > "$FULL_PATH/src/ThemeAnimation.tsx" << 'ANIMEOF'
import React from 'react';
import { useCurrentFrame, interpolate, spring, AbsoluteFill } from 'remotion';

const ThemeAnimation: React.FC = () => {
  const frame = useCurrentFrame();
  const fps = 30;

  const scale = spring({ fps, frame, config: { damping: 12, stiffness: 100 } });
  const opacity = interpolate(frame, [0, 30, 120, 150], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const floatY = interpolate(frame, [0, 75, 150], [0, -20, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{ backgroundColor: '#0a0a1a', justifyContent: 'center', alignItems: 'center' }}>
      <div style={{
        transform: `scale(${scale}) translateY(${floatY})`,
        opacity,
      }}>
        <div style={{
          fontSize: 100,
          fontFamily: 'Arial Black, sans-serif',
          fontWeight: 'bold',
          color: '#fff',
          textShadow: '0 0 30px rgba(255, 0, 255, 0.8), 0 0 60px rgba(0, 255, 255, 0.6)',
        }}>
          EMOWOWO
        </div>
      </div>
    </AbsoluteFill>
  );
};

export default ThemeAnimation;
ANIMEOF

# Create index.tsx with registerRoot
cat > "$FULL_PATH/src/index.tsx" << 'INDEXEOF'
import { Composition, registerRoot } from 'remotion';
import React from 'react';
import ThemeAnimation from './ThemeAnimation';

const Root: React.FC = () => {
  return (
    <Composition
      id="ThemeAnimation"
      component={ThemeAnimation}
      durationInFrames={150}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};

registerRoot(Root);
INDEXEOF

# Create public folder placeholder
touch "$FULL_PATH/public/.gitkeep"

# Install dependencies
echo -e "${GREEN}📦 Installing dependencies...${NC}"
cd "$FULL_PATH"
npm install 2>/dev/null || npm install

# Open in editor (only if not deferring)
if [ "$DEFER_OPEN" = false ]; then
  echo -e "${GREEN}💻 Opening in $EDITOR...${NC}"
  case $EDITOR in
    cursor)
      open -a Cursor "$FULL_PATH"
      ;;
    vscode)
      code "$FULL_PATH"
      ;;
    *)
      open -a Cursor "$FULL_PATH"
      ;;
  esac
fi

# Function to kill process on port
kill_port() {
  local p=$1
  lsof -ti :$p | xargs kill -9 2>/dev/null || true
  sleep 1
}

# Function to find available port
find_available_port() {
  local start=$1
  local port=$start
  while [ $port -lt $start+100 ]; do
    if ! lsof -i :$port >/dev/null 2>&1; then
      echo $port
      return 0
    fi
    port=$((port + 1))
  done
  echo $start
  return 1
}

# Function to check if server is responding
check_server() {
  local url="http://localhost:$1"
  local response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
  [ "$response" = "200" ]
}

# Function to start preview server
start_preview() {
  local port=$1
  cd "$FULL_PATH"
  nohup npx remotion preview --port $port > /tmp/remotionmax-preview.log 2>&1 &
  echo $!
}

# Function to fix common issues
fix_issues() {
  echo -e "${YELLOW}🔧 Attempting to fix issues...${NC}"
  
  # Fix registerRoot issues
  if grep -q "registerRoot" "$FULL_PATH/src/index.tsx" 2>/dev/null; then
    echo -e "${GREEN}✓ registerRoot found${NC}"
  else
    echo -e "${YELLOW}⚠️  Adding registerRoot...${NC}"
    cat > "$FULL_PATH/src/index.tsx" << 'FIXROOT'
import { Composition, registerRoot } from 'remotion';
import React from 'react';
import ThemeAnimation from './ThemeAnimation';

const Root: React.FC = () => {
  return (
    <Composition
      id="ThemeAnimation"
      component={ThemeAnimation}
      durationInFrames={150}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};

registerRoot(Root);
FIXROOT
  fi
  
  # Reinstall if node_modules has issues
  if [ ! -d "$FULL_PATH/node_modules" ]; then
    echo -e "${YELLOW}⚠️  Reinstalling dependencies...${NC}"
    cd "$FULL_PATH"
    npm install
  fi
}

# Start preview with retry logic
echo -e "${GREEN}🚀 Starting preview server...${NC}"

# Force clean all existing remotion processes if --force flag is set
if [ "$FORCE_CLEAN" = true ]; then
  echo -e "${YELLOW}🔪 Force cleaning all existing preview servers...${NC}"
  pkill -f "remotion preview" 2>/dev/null || true
  sleep 2
fi

CURRENT_PORT=$PORT
RETRY_COUNT=0
SERVER_PID=""

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  # Kill any existing process on the port
  kill_port $CURRENT_PORT
  
  # Start server
  echo -e "${BLUE}   Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES on port $CURRENT_PORT...${NC}"
  SERVER_PID=$(start_preview $CURRENT_PORT)
  
  # Wait for build
  echo -e "${BLUE}   Waiting for build...${NC}"
  sleep 10
  
  # Check if server is responding
  if check_server $CURRENT_PORT; then
    echo -e "${GREEN}✅ Server is responding!${NC}"
    
    # Double check with actual content
    sleep 3
    if curl -s "http://localhost:$CURRENT_PORT" | grep -q "remotion"; then
      echo -e "${GREEN}✅ Preview is ready!${NC}"
      break
    fi
  fi
  
  # If failed, check log and fix issues
  echo -e "${RED}❌ Server not responding properly${NC}"
  
  # Kill current server
  if [ -n "$SERVER_PID" ]; then
    kill $SERVER_PID 2>/dev/null || true
  fi
  kill_port $CURRENT_PORT
  
  # Fix common issues
  fix_issues
  
  # Try next port
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    CURRENT_PORT=$(find_available_port $((CURRENT_PORT + 1)))
    echo -e "${YELLOW}   Trying new port: $CURRENT_PORT${NC}"
  fi
done

# Final check
if ! check_server $CURRENT_PORT; then
  echo -e "${RED}❌ Failed after $MAX_RETRIES attempts${NC}"
  echo -e "${RED}   Check log: /tmp/remotionmax-preview.log${NC}"
  echo ""
  echo -e "${BLUE}   Last 30 lines of log:${NC}"
  tail -30 /tmp/remotionmax-preview.log
  exit 1
fi

echo -e "${BLUE}⏳ Waiting for Remotion to compile your animation...${NC}"
COMPILE_WAIT=0
while [ $COMPILE_WAIT -lt 15 ]; do
  sleep 2
  COMPILE_WAIT=$((COMPILE_WAIT + 2))
  if curl -s "http://localhost:$CURRENT_PORT" | grep -q "Remotion"; then
    echo -e "${GREEN}✅ Compilation complete!${NC}"
    break
  fi
  echo -e "${BLUE}   Still compiling... ($COMPILE_WAIT/15s)${NC}"
done

# Get local IP
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "localhost")

# Auto-open browser - now all code is ready
if [ "$DEFER_OPEN" = false ]; then
  echo -e "${GREEN}🌐 Opening preview in browser...${NC}"
  sleep 1
  open "http://localhost:$CURRENT_PORT"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Animation Studio Ready!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${PURPLE}📁 Location:${NC} $FULL_PATH"
echo -e "   ${PURPLE}💻 Editor:${NC} $EDITOR (should be open)"
echo -e "   ${PURPLE}🔗 Preview:${NC} http://localhost:$CURRENT_PORT"
echo -e "   ${PURPLE}🌐 Network:${NC} http://$LOCAL_IP:$CURRENT_PORT"
echo ""
echo -e "${YELLOW}   Edit src/ThemeAnimation.tsx to customize your animation!${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}   Useful commands:${NC}"
echo "   - Render: npx remotion render ThemeAnimation out.mp4"
echo "   - GIF: npx remotion render ThemeAnimation out.gif --codec=gif"
echo "   - Logs: tail -f /tmp/remotionmax-preview.log"
echo ""
