# Task Observer Setup (Antigravity)

Follow these steps to install the Task Observer skill into Antigravity.

### 1. Install the Skill

```bash
# From the emerge_app project directory
npx skills add .agents/skills/task-observer --agent antigravity --yes
```

If the skill needs to be installed globally (not project-linked):

```bash
npx skills add .agents/skills/task-observer --agent antigravity --global --yes
```

### 2. Verify Installation

```bash
npx skills list --agent antigravity
```

The output should include `task-observer`.

### 3. Verify Scripts

The skill relies on Python scripts in the `scripts/` directory. Ensure Python 3.10+ is available:

```bash
python --version
```

The scripts use only the standard library (no pip installs required).

### 4. Restart Antigravity

Restart the Antigravity application after skill installation to load the new skill.

### 5. Verify Connection

After restarting, start a new chat and confirm the skill activates when
beginning a work session (you should see task-observer session-start prompts).
