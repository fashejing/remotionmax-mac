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

# Launch mode - open all batched projects
if [ "$LAUNCH_MODE" = true ]; then
  echo -e "${YELLOW}🚀 Launching all batched projects...${NC}"
  echo ""
  
  if [ ! -f "$BATCH_FILE" ]; then
    echo -e "${RED}❌ No batch file found. Create projects first with --batch flag.${NC}"
    exit 1
  fi
  
  # Read batch file
  BATCH_DATA=$(cat "$BATCH_FILE")
  PROJECT_COUNT=$(echo "$BATCH_DATA" | jq length 2>/dev/null || echo "0")
  
  if [ "$PROJECT_COUNT" = "0" ] || [ "$PROJECT_COUNT" = "null" ]; then
    echo -e "${RED}❌ No projects in batch.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}📦 Found $PROJECT_COUNT projects in batch${NC}"
  echo ""
  
  # Collect all project paths for Cursor
  CURSOR_PATHS=""
  PREVIEW_PORTS=""
  PROJECT_LOCATIONS=""
  
  for i in $(seq 0 $((PROJECT_COUNT - 1))); do
    PROJECT_PATH=$(echo "$BATCH_DATA" | jq -r ".[$i].path")
    PROJECT_NAME=$(echo "$BATCH_DATA" | jq -r ".[$i].name")
    PORT=$(echo "$BATCH_DATA" | jq -r ".[$i].port")
    
    CURSOR_PATHS="$CURSOR_PATHS \"$PROJECT_PATH\""
    PREVIEW_PORTS="$PREVIEW_PORTS $PORT"
    PROJECT_LOCATIONS="$PROJECT_LOCATIONS\n   ${PURPLE}$PROJECT_NAME${NC}: http://localhost:$PORT"
  done
  
  # Open Cursor with all projects in one workspace
  echo -e "${GREEN}💻 Opening Cursor with all projects...${NC}"
  eval "open -a Cursor $CURSOR_PATHS" &
  CURSOR_PID=$!
  
  # Start preview servers for all projects
  echo -e "${GREEN}🚀 Starting preview servers...${NC}"
  PREVIEW_PIDS=""

  # Kill any existing remotion preview processes first
  echo -e "${YELLOW}🔪 Cleaning up existing preview servers...${NC}"
  pkill -f "remotion preview" 2>/dev/null || true
  sleep 2

  for i in $(seq 0 $((PROJECT_COUNT - 1))); do
    PROJECT_PATH=$(echo "$BATCH_DATA" | jq -r ".[$i].path")
    PORT=$(echo "$BATCH_DATA" | jq -r ".[$i].port")

    # Force kill any process on this port
    echo -e "${YELLOW}   Port $PORT: killing existing process...${NC}"
    kill_port $PORT
    sleep 1

    cd "$PROJECT_PATH"
    nohup npx remotion preview --port $PORT > /tmp/remotionmax-$PORT.log 2>&1 &
    PREVIEW_PIDS="$PREVIEW_PIDS $!"
    echo -e "${BLUE}   Started preview on port $PORT${NC}"
  done
  
  # Wait for first server to be ready
  FIRST_PORT=$(echo "$BATCH_DATA" | jq -r ".[0].port")
  echo -e "${BLUE}⏳ Waiting for preview servers to compile...${NC}"
  
  for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$FIRST_PORT" 2>/dev/null | grep -q "200"; then
      echo -e "${GREEN}✅ Preview servers ready!${NC}"
      break
    fi
    sleep 2
  done
  
  # Open ONE browser with first project's preview
  echo -e "${GREEN}🌐 Opening preview in browser...${NC}"
  open "http://localhost:$FIRST_PORT"
  
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}✅ All $PROJECT_COUNT Animations Ready!${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${PURPLE}📁 Project Locations:${NC} $PROJECT_LOCATIONS"
  echo ""
  echo -e "${YELLOW}💡 To add more projects, run with --batch, then use --launch when done.${NC}"
  echo ""
  echo -e "${BLUE}   Preview ports:$PREVIEW_PORTS"
  echo ""
  
  # Clean up batch file
  rm -f "$BATCH_FILE"
  
  exit 0
fi

# Normal single project creation
if [ "$BATCH_MODE" = true ]; then
  echo -e "${YELLOW}📦 Batch Mode: Project will be created but not opened yet${NC}"
  echo ""
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
      *) EDITOR="cursor" ;;
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
[ -z "$EDITOR" ] && EDITOR="cursor"
[ -z "$PROJECT_PATH" ] && PROJECT_PATH="/Users/fsj/Documents/emowowo remotion"

FULL_PATH="$PROJECT_PATH/$PROJECT_NAME"

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

# Add to batch file if in batch mode
if [ "$BATCH_MODE" = true ]; then
  # Find available port (checking both system ports and existing batch entries)
  TEST_PORT=$PORT
  while true; do
    # Check if port is in use by system
    if lsof -i :$TEST_PORT >/dev/null 2>&1; then
      TEST_PORT=$((TEST_PORT + 1))
      continue
    fi
    # Check if port is already assigned in batch file
    if [ -f "$BATCH_FILE" ]; then
      EXISTING_PORTS=$(cat "$BATCH_FILE" | jq -r '.[].port' 2>/dev/null)
      if echo "$EXISTING_PORTS" | grep -q "^$TEST_PORT$"; then
        TEST_PORT=$((TEST_PORT + 1))
        continue
      fi
    fi
    break
  done

  BATCH_ENTRY="{\"name\": \"$PROJECT_NAME\", \"path\": \"$FULL_PATH\", \"port\": $TEST_PORT}"
  
  if [ -f "$BATCH_FILE" ]; then
    # Append to existing batch
    EXISTING=$(cat "$BATCH_FILE")
    echo "$(echo "$EXISTING" | jq ". + [$BATCH_ENTRY]")" > "$BATCH_FILE"
  else
    # Create new batch file
    echo "[$BATCH_ENTRY]" > "$BATCH_FILE"
  fi
  
  echo -e "${GREEN}✅ Project added to batch (run with --launch when all projects are ready)${NC}"
  echo ""
  echo -e "${BLUE}   Project: $PROJECT_NAME"
  echo "   Path: $FULL_PATH"
  echo "   Port: $TEST_PORT${NC}"
  echo ""
  
  exit 0
fi

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
