# Claude Mem Setup (Antigravity)

Follow these steps to install the Claude Mem skill into Antigravity.

### 1. Verify opencode-mem Is Installed

Claude Mem requires the `opencode-mem` plugin. Verify it's installed:

```bash
memory({ mode: "list", limit: 1 })
```

If this returns an error or "no tool found", install opencode-mem:

```bash
npm install -g opencode-mem
opencode-mem install
```

This sets up the SQLite vector database at `~/.opencode-mem/data/` and starts
the web UI at `http://127.0.0.1:4747`.

### 2. Install the Skill

```bash
# From the emerge_app project directory
npx skills add .agents/skills/claude-mem --agent antigravity --yes
```

If installing globally:

```bash
npx skills add .agents/skills/claude-mem --agent antigravity --global --yes
```

### 3. Verify Installation

```bash
npx skills list --agent antigravity
```

The output should include `claude-mem`.

### 4. Configure Memory Scope

The skill defaults to `scope: "project"` (current project only). If you want
cross-project memory, set the scope in Antigravity's configuration or use
`scope: "all-projects"` in memory queries.

### 5. Restart Antigravity

Restart the Antigravity application after skill installation.

### 6. Verify Memory is Working

```bash
memory({ mode: "add", content: "Test memory for emerge_app project" })
memory({ mode: "search", query: "emerge_app project" })
```

If both commands succeed, the skill is operational.
