#!/bin/bash
# ─────────────────────────────────────────────
#  TAC Setup — Think. Architect. Code.
#  One script installs everything.
#  Usage: bash <(curl -fsSL https://raw.githubusercontent.com/waghelapritesh/tac/main/setup.sh)
# ─────────────────────────────────────────────

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "  ${BLUE}▸${NC} $1"; }
success() { echo -e "  ${GREEN}✓${NC} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC} $1"; }
error()   { echo -e "  ${RED}✗${NC} $1"; }

echo ""
echo -e "  ${BLUE}+${PURPLE}  ^${CYAN}  <${NC}  ${BOLD}TAC${NC}"
echo -e "  ${DIM}Think. Architect. Code.${NC}"
echo ""

# ─── Prerequisites ───────────────────────────

info "Checking prerequisites..."

# Git
if ! command -v git &>/dev/null; then
  error "Git is required. Install it first."
  exit 1
fi
success "Git $(git --version | cut -d' ' -f3)"

# Node.js
if ! command -v node &>/dev/null; then
  warn "Node.js not found. Installing Node.js 20..."
  if command -v apt-get &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >/dev/null 2>&1
    sudo apt-get install -y nodejs >/dev/null 2>&1
  elif command -v brew &>/dev/null; then
    brew install node@20 >/dev/null 2>&1
  else
    error "Cannot auto-install Node.js. Install Node.js 20+ manually."
    exit 1
  fi
fi
success "Node.js $(node --version)"
success "npm $(npm --version)"

# ─── Install TAC CLI ─────────────────────────

TAC_DIR="$HOME/.claude/tac-cli"
mkdir -p "$HOME/.claude"

info "Installing TAC CLI..."

if [ -d "$TAC_DIR" ]; then
  info "Updating existing installation..."
  cd "$TAC_DIR" && git pull origin main >/dev/null 2>&1
  success "Updated TAC CLI"
else
  git clone https://github.com/waghelapritesh/tac-cli.git "$TAC_DIR" >/dev/null 2>&1
  success "Cloned TAC CLI"
fi

# Install deps
info "Installing dependencies..."
cd "$TAC_DIR" && npm install --silent 2>/dev/null
success "Dependencies installed"

# Build
info "Building..."
cd "$TAC_DIR" && npx tsup --silent 2>/dev/null
success "CLI built"

# ─── Link globally ───────────────────────────

info "Setting up 'tac-ai' command..."

# Create wrapper script (avoids conflict with Linux `tac` command)
sudo tee /usr/local/bin/tac-ai >/dev/null << 'WRAPPER'
#!/bin/bash
node "$HOME/.claude/tac-cli/dist/cli.js" "$@"
WRAPPER
sudo chmod +x /usr/local/bin/tac-ai
success "'tac-ai' command available globally"

# Add bash alias so 'tac' also works (in new shells)
if ! grep -q 'alias tac=tac-ai' "$HOME/.bashrc" 2>/dev/null; then
  echo 'alias tac=tac-ai' >> "$HOME/.bashrc"
  success "Added 'tac' alias to .bashrc"
fi

# ─── Install TAC Skills (optional, for AI agent users) ────

SKILLS_DIR="$HOME/.claude/tac"

info "Installing TAC skills (for Claude Code/Gemini CLI users)..."

if [ -d "$SKILLS_DIR" ]; then
  cd "$SKILLS_DIR" && git pull origin main >/dev/null 2>&1
  success "Updated TAC skills"
else
  git clone https://github.com/waghelapritesh/tac.git "$SKILLS_DIR" >/dev/null 2>&1
  success "Cloned TAC skills"
fi

# Link skills
mkdir -p "$HOME/.claude/skills"
for d in "$SKILLS_DIR"/skills/*/; do
  name=$(basename "$d")
  ln -sfn "$SKILLS_DIR/skills/$name" "$HOME/.claude/skills/$name" 2>/dev/null
done
SKILL_COUNT=$(ls -d "$HOME/.claude/skills"/tac-* 2>/dev/null | wc -l)
success "Linked $SKILL_COUNT skills"

# ─── Run tests ───────────────────────────────

echo ""
info "Running tests..."
cd "$TAC_DIR"
TEST_OUTPUT=$(npx vitest run 2>&1)
TEST_COUNT=$(echo "$TEST_OUTPUT" | grep "Tests" | grep -oP '\d+ passed')
TEST_FILES=$(echo "$TEST_OUTPUT" | grep "Test Files" | grep -oP '\d+ passed')

if echo "$TEST_OUTPUT" | grep -q "passed"; then
  success "Tests: $TEST_COUNT ($TEST_FILES files)"
else
  warn "Some tests failed. Run 'cd ~/.claude/tac-cli && npx vitest run' to see details."
fi

# ─── Verify ──────────────────────────────────

echo ""
VERSION=$(tac-ai --version 2>/dev/null || echo "unknown")
success "TAC v$VERSION installed successfully!"

echo ""
echo -e "  ${BOLD}Usage:${NC}"
echo ""
echo -e "  ${CYAN}tac-ai${NC}                 Interactive REPL"
echo -e "  ${CYAN}tac-ai settings${NC}        Configure AI provider + API key"
echo -e "  ${CYAN}tac-ai new \"idea\"${NC}      Full pipeline: ASK → DESIGN → SAFE → AUTO → SHIP"
echo -e "  ${CYAN}tac-ai build \"feat\"${NC}    Smart build (skips Q&A if clear)"
echo -e "  ${CYAN}tac-ai think \"idea\"${NC}    Explore only (ASK + DESIGN)"
echo -e "  ${CYAN}tac-ai go${NC}              Resume from checkpoint"
echo -e "  ${CYAN}tac-ai ship${NC}            Safety + review + PR"
echo -e "  ${CYAN}tac-ai dashboard${NC}       Live progress TUI"
echo -e "  ${CYAN}tac-ai do${NC}              Advanced operations"
echo -e "  ${CYAN}tac-ai status${NC}          Current progress"
echo ""
echo -e "  ${DIM}First run: tac-ai settings (to set your API key)${NC}"
echo ""

# ─── Telegram Bot (optional) ─────────────────

echo -e "  ${BOLD}Optional: Telegram Bot${NC}"
echo ""
echo -e "  TAC can also run as a hosted Telegram bot (multi-user, public)."
echo -e "  This requires PostgreSQL, Redis, and a Telegram bot token."
echo ""
read -p "  Install Telegram Bot integration? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo ""
  info "Installing TAC Bot..."

  # Check Python
  if ! command -v python3 &>/dev/null; then
    error "Python 3 is required for the Telegram bot."
    echo -e "  ${DIM}Install with: sudo apt install python3 python3-venv${NC}"
    exit 1
  fi

  # Check PostgreSQL
  if ! command -v psql &>/dev/null; then
    warn "PostgreSQL not found. Install with: sudo apt install postgresql"
  fi

  # Check Redis
  if ! command -v redis-cli &>/dev/null; then
    warn "Redis not found. Install with: sudo apt install redis-server"
  fi

  BOT_DIR="/opt/tac-bot"

  if [ -d "$BOT_DIR" ]; then
    info "TAC Bot already installed at $BOT_DIR"
  else
    sudo mkdir -p "$BOT_DIR"
    sudo chown "$(whoami):$(whoami)" "$BOT_DIR"
    git clone https://github.com/waghelapritesh/tac-bot.git "$BOT_DIR" >/dev/null 2>&1
    cd "$BOT_DIR"
    python3 -m venv .venv
    .venv/bin/pip install -e . >/dev/null 2>&1
    success "TAC Bot installed at $BOT_DIR"
  fi

  echo ""
  echo -e "  ${BOLD}Next steps for Telegram Bot:${NC}"
  echo -e "  1. Create bot via ${CYAN}@BotFather${NC} on Telegram"
  echo -e "  2. Edit ${CYAN}$BOT_DIR/.env${NC} with your tokens"
  echo -e "  3. Run: ${CYAN}cd $BOT_DIR && .venv/bin/alembic upgrade head${NC}"
  echo -e "  4. Run: ${CYAN}sudo systemctl enable --now tac-bot${NC}"
  echo ""
else
  echo ""
  echo -e "  ${DIM}Skipped. Run this script again to add Telegram later.${NC}"
  echo ""
fi

echo -e "  ${GREEN}${BOLD}Setup complete!${NC}"
echo ""
