#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");

function main() {
  const cwd = process.cwd();
  const stateFile = path.join(cwd, ".tac", "state.json");

  // If no .tac/state.json, exit silently
  if (!fs.existsSync(stateFile)) {
    return;
  }

  let state;
  try {
    state = JSON.parse(fs.readFileSync(stateFile, "utf8"));
  } catch {
    // Malformed JSON — exit silently
    return;
  }

  const feature = state.current_feature || "no feature";
  const stage = state.current_stage || "IDLE";
  const stack = state.stack || "unknown";

  const parts = [`TAC \u25C6 ${feature} \u25C6 ${stage} \u25C6 ${stack}`];

  // Check for pending checkpoint
  const pendingFile = path.join(cwd, ".tac", "context", "pending.json");
  if (fs.existsSync(pendingFile)) {
    try {
      const pending = JSON.parse(fs.readFileSync(pendingFile, "utf8"));
      const pendingFeature = pending.feature || feature;
      parts.push(`Pending: /tac-go to resume ${pendingFeature}`);
    } catch {
      // Malformed pending.json — just show the pending hint without feature name
      parts.push(`Pending: /tac-go to resume ${feature}`);
    }
  }

  process.stdout.write(parts.join("\n") + "\n");
}

main();
