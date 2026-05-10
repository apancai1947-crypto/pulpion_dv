# Design: Install git-commit Skill from awesome-copilot

## Goal
Install the `git-commit` skill from the `https://github.com/github/awesome-copilot.git` repository into the local Antigravity skills directory.

## Current State
- Local skills directory: `C:\Users\lenovo\.gemini\antigravity\skills`
- Remote skill location: `https://github.com/github/awesome-copilot.git` at `skills/git-commit`

## Proposed Design
The installation will be performed using a temporary clone approach to ensure all necessary files are captured while keeping the local environment clean.

### Steps
1. **Create Temporary Directory**: Create a directory named `temp_skill_install` in the current workspace.
2. **Clone Repository**: Execute `git clone https://github.com/github/awesome-copilot.git temp_skill_install`.
3. **Ensure Target Directory**: Create `C:\Users\lenovo\.gemini\antigravity\skills\git-commit` if it doesn't exist.
4. **Copy Skill Files**: Copy all contents from `temp_skill_install/skills/git-commit/` to `C:\Users\lenovo\.gemini\antigravity\skills\git-commit/`.
5. **Verification**: Verify that `C:\Users\lenovo\.gemini\antigravity\skills\git-commit\SKILL.md` exists and contains the expected content.
6. **Cleanup**: Remove the `temp_skill_install` directory.

## Success Criteria
- The directory `C:\Users\lenovo\.gemini\antigravity\skills\git-commit` exists.
- The file `C:\Users\lenovo\.gemini\antigravity\skills\git-commit\SKILL.md` is present and valid.
- No temporary files are left in the workspace.

## Risk Assessment
- **Disk Space**: The repository might be large. However, `awesome-copilot` is typically manageable.
- **Git Availability**: Assumes `git` is installed and accessible in the system path.
