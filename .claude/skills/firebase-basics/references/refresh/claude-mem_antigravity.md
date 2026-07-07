# Refresh Claude Mem (Antigravity)

Follow these steps to refresh the Claude Mem skill in Antigravity.

1. **Check Available Version:**
   ```bash
   npx -y skills add .agents/skills/claude-mem --list
   ```

2. **Update the Skill:**
   ```bash
   # Project-level
   npx -y skills update --agent antigravity --yes

   # Global-level (if installed globally)
   npx -y skills update --agent antigravity --global --yes
   ```

3. **Verify opencode-mem Is Up to Date:**
   ```bash
   npm update -g opencode-mem
   ```

4. **Run Memory Health Check:**
   ```bash
   memory({ mode: "list", limit: 5 })
   ```

5. **Restart Antigravity** to load the updated skill.
