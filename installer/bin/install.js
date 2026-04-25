#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

// ─────────────────────────────────────────────
//  TAC Installer — Think. Architect. Code.
//  Usage: npx tac-cc@latest
// ─────────────────────────────────────────────

const isWindows = os.platform() === 'win32';
const home = os.homedir();
const claudeDir = path.join(home, '.claude');
const tacDir = path.join(claudeDir, 'tac');
const skillsDir = path.join(claudeDir, 'skills');
const REPO = 'https://github.com/waghelapritesh/tac.git';
const CLI_REPO = 'https://github.com/waghelapritesh/tac-cli.git';
const cliDir = path.join(claudeDir, 'tac-cli');

// Colors
const c = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  blue: '\x1b[34m',
  green: '\x1b[32m',
  cyan: '\x1b[36m',
  purple: '\x1b[35m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  dim: '\x1b[2m',
};

function log(msg) { console.log(msg); }
function info(msg) { log(`${c.blue}  ▸${c.reset} ${msg}`); }
function success(msg) { log(`${c.green}  ✓${c.reset} ${msg}`); }
function warn(msg) { log(`${c.yellow}  ⚠${c.reset} ${msg}`); }
function error(msg) { log(`${c.red}  ✗${c.reset} ${msg}`); }

function run(cmd, opts = {}) {
  try {
    return execSync(cmd, { stdio: 'pipe', encoding: 'utf-8', ...opts }).trim();
  } catch (e) {
    if (!opts.allowFail) throw e;
    return null;
  }
}

function banner() {
  log('');
  log(`${c.bold}${c.blue}  +${c.purple}  ^${c.cyan}  <${c.reset}  ${c.bold}TAC${c.reset}`);
  log(`${c.dim}  Think. Architect. Code.${c.reset}`);
  log('');
}

function checkPrereqs() {
  // Check git
  try {
    run('git --version');
  } catch {
    error('Git is required but not found. Install git and retry.');
    process.exit(1);
  }

  // Check Claude Code
  const claudeCheck = run('claude --version', { allowFail: true });
  if (!claudeCheck) {
    warn('Claude Code CLI not detected. TAC requires Claude Code to function.');
    warn('Install from: https://claude.ai/code');
  }
}

function ensureDirs() {
  if (!fs.existsSync(claudeDir)) {
    fs.mkdirSync(claudeDir, { recursive: true });
    info('Created ~/.claude/');
  }
  if (!fs.existsSync(skillsDir)) {
    fs.mkdirSync(skillsDir, { recursive: true });
    info('Created ~/.claude/skills/');
  }
}

function cloneOrUpdate() {
  if (fs.existsSync(tacDir)) {
    // Update existing installation
    info('Existing TAC installation found — updating...');
    try {
      run('git pull origin main', { cwd: tacDir });
      success('Updated to latest version');
    } catch {
      warn('Git pull failed — trying fresh clone...');
      const backup = tacDir + '.backup.' + Date.now();
      fs.renameSync(tacDir, backup);
      warn(`Old installation backed up to ${backup}`);
      run(`git clone ${REPO} "${tacDir}"`);
      success('Fresh clone complete');
    }
  } else {
    // Fresh install
    info('Cloning TAC...');
    run(`git clone ${REPO} "${tacDir}"`);
    success('Cloned TAC repository');
  }
}

function linkSkills() {
  const tacSkillsDir = path.join(tacDir, 'skills');
  if (!fs.existsSync(tacSkillsDir)) {
    error('Skills directory not found in TAC repo');
    process.exit(1);
  }

  const skills = fs.readdirSync(tacSkillsDir).filter(f => {
    return fs.statSync(path.join(tacSkillsDir, f)).isDirectory();
  });

  let linked = 0;
  let skipped = 0;

  for (const skill of skills) {
    const source = path.join(tacSkillsDir, skill);
    const target = path.join(skillsDir, skill);

    // Remove existing link/dir if it exists
    if (fs.existsSync(target)) {
      const stat = fs.lstatSync(target);
      if (stat.isSymbolicLink()) {
        fs.unlinkSync(target);
      } else {
        // Skip non-symlink dirs (user's own skills)
        const skillMd = path.join(target, 'SKILL.md');
        if (fs.existsSync(skillMd)) {
          const content = fs.readFileSync(skillMd, 'utf-8');
          if (!content.includes('name: tac-')) {
            skipped++;
            continue; // Not a TAC skill, don't overwrite
          }
        }
        fs.rmSync(target, { recursive: true, force: true });
      }
    }

    // Create symlink
    if (isWindows) {
      // Windows: use junction (doesn't require admin)
      try {
        execSync(`mklink /J "${target}" "${source}"`, { stdio: 'pipe', shell: true });
      } catch {
        // Fallback: copy directory
        fs.cpSync(source, target, { recursive: true });
      }
    } else {
      fs.symlinkSync(source, target, 'dir');
    }
    linked++;
  }

  success(`Linked ${linked} skills to ~/.claude/skills/`);
  if (skipped > 0) {
    info(`Skipped ${skipped} non-TAC skills (preserved your custom skills)`);
  }
}

function installCLI() {
  info('Installing TAC CLI (standalone runtime)...');

  if (fs.existsSync(cliDir)) {
    // Update
    try {
      run('git pull origin main', { cwd: cliDir });
      success('Updated TAC CLI');
    } catch {
      warn('Git pull failed for CLI — trying fresh clone...');
      fs.rmSync(cliDir, { recursive: true, force: true });
      run(`git clone ${CLI_REPO} "${cliDir}"`);
      success('Fresh CLI clone complete');
    }
  } else {
    run(`git clone ${CLI_REPO} "${cliDir}"`);
    success('Cloned TAC CLI');
  }

  // Install dependencies and build
  info('Installing CLI dependencies...');
  run('npm install', { cwd: cliDir });
  success('Dependencies installed');

  info('Building CLI...');
  run('npx tsup', { cwd: cliDir });
  success('CLI built');

  // Install globally via npm link
  info('Linking `tac` command globally...');
  try {
    run('npm link', { cwd: cliDir });
    success('`tac` command available globally');
  } catch {
    // npm link may fail without sudo on some systems
    warn('Could not link globally. You can run TAC with:');
    warn(`  node ${path.join(cliDir, 'dist', 'cli.js')}`);
    warn('Or add to PATH manually.');
  }

  // Verify
  const tacCheck = run('tac --version', { allowFail: true });
  if (tacCheck) {
    success(`TAC CLI v${tacCheck} ready`);
  }
}

function getVersion() {
  const readmePath = path.join(tacDir, 'README.md');
  if (fs.existsSync(readmePath)) {
    const content = fs.readFileSync(readmePath, 'utf-8');
    const match = content.match(/### (v[\d.]+)/);
    return match ? match[1] : 'unknown';
  }
  return 'unknown';
}

function showSummary() {
  const version = getVersion();
  const skillCount = fs.readdirSync(path.join(tacDir, 'skills')).filter(f => {
    return fs.statSync(path.join(tacDir, 'skills', f)).isDirectory();
  }).length;

  log('');
  log(`${c.green}${c.bold}  TAC installed successfully!${c.reset}`);
  log('');
  log(`  ${c.dim}Version:${c.reset}  ${version}`);
  log(`  ${c.dim}Skills:${c.reset}   ${skillCount} commands`);
  log(`  ${c.dim}Location:${c.reset} ${tacDir}`);
  log('');
  log(`  ${c.bold}Two ways to use TAC:${c.reset}`);
  log('');
  log(`  ${c.bold}1. Standalone CLI${c.reset} (like GSD-2)`);
  log(`  ${c.cyan}tac${c.reset}             Interactive REPL`);
  log(`  ${c.cyan}tac new "idea"${c.reset}  Full auto pipeline`);
  log(`  ${c.cyan}tac build${c.reset}       Smart build`);
  log(`  ${c.cyan}tac dashboard${c.reset}   Live progress TUI`);
  log('');
  log(`  ${c.bold}2. AI Agent Plugin${c.reset} (Claude Code, Gemini CLI, etc.)`);
  log(`  ${c.cyan}/tac-init${c.reset}       Initialize in your project`);
  log(`  ${c.cyan}/tac-new${c.reset}        Full auto pipeline`);
  log(`  ${c.cyan}/tac-build${c.reset}      Smart build`);
  log(`  ${c.cyan}/tac-do${c.reset}         Advanced operations`);
  log('');
  log(`  ${c.dim}Docs: https://github.com/waghelapritesh/tac${c.reset}`);
  log('');
}

// ─────────────────────────────────────────────
//  Main
// ─────────────────────────────────────────────

async function main() {
  banner();

  const args = process.argv.slice(2);
  const isUninstall = args.includes('--uninstall') || args.includes('-u');

  if (isUninstall) {
    info('Uninstalling TAC...');
    // Remove skill symlinks
    if (fs.existsSync(skillsDir)) {
      const entries = fs.readdirSync(skillsDir);
      let removed = 0;
      for (const entry of entries) {
        const p = path.join(skillsDir, entry);
        if (entry.startsWith('tac-') && fs.existsSync(p)) {
          fs.rmSync(p, { recursive: true, force: true });
          removed++;
        }
      }
      success(`Removed ${removed} skill links`);
    }
    if (fs.existsSync(cliDir)) {
      run('npm unlink', { cwd: cliDir, allowFail: true });
      fs.rmSync(cliDir, { recursive: true, force: true });
      success('Removed ~/.claude/tac-cli/');
    }
    if (fs.existsSync(tacDir)) {
      fs.rmSync(tacDir, { recursive: true, force: true });
      success('Removed ~/.claude/tac/');
    }
    log(`\n${c.green}  TAC uninstalled.${c.reset}\n`);
    return;
  }

  checkPrereqs();
  ensureDirs();
  cloneOrUpdate();
  linkSkills();
  installCLI();
  showSummary();
}

main().catch(e => {
  error(`Installation failed: ${e.message}`);
  process.exit(1);
});
