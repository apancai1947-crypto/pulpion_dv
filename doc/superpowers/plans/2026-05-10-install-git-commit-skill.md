# git-commit Skill Installation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install the `git-commit` skill from the local temporary directory to the Antigravity skills repository.

**Architecture:** Verify the source content, create the target directory, and copy the `SKILL.md` file.

**Tech Stack:** Shell (PowerShell)

---

### Task 1: Preparation and Verification

**Files:**
- Source: `C:/Users/lenovo/AppData/Local/Temp/awesome-copilot/skills/git-commit/SKILL.md`
- Target Dir: `C:\Users\lenovo\.gemini\antigravity\skills\git-commit`

- [ ] **Step 1: Verify source file exists**
  Run: `Test-Path "C:/Users/lenovo/AppData/Local/Temp/awesome-copilot/skills/git-commit/SKILL.md"`
  Expected: `True`

- [ ] **Step 2: Create target directory**
  Run: `New-Item -ItemType Directory -Force -Path "C:\Users\lenovo\.gemini\antigravity\skills\git-commit"`
  Expected: Directory created.

### Task 2: Copy and Install

**Files:**
- Copy: `C:/Users/lenovo/AppData/Local/Temp/awesome-copilot/skills/git-commit/SKILL.md` -> `C:\Users\lenovo\.gemini\antigravity\skills\git-commit\SKILL.md`

- [ ] **Step 1: Copy the file**
  Run: `Copy-Item -Path "C:/Users/lenovo/AppData/Local/Temp/awesome-copilot/skills/git-commit/SKILL.md" -Destination "C:\Users\lenovo\.gemini\antigravity\skills\git-commit\SKILL.md" -Force`
  Expected: File copied.

### Task 3: Final Verification

- [ ] **Step 1: Verify target file content**
  Run: `Get-Content "C:\Users\lenovo\.gemini\antigravity\skills\git-commit\SKILL.md" -TotalCount 10`
  Expected: YAML frontmatter showing `name: git-commit`.

- [ ] **Step 2: List target directory**
  Run: `dir "C:\Users\lenovo\.gemini\antigravity\skills\git-commit"`
  Expected: `SKILL.md` is present.
