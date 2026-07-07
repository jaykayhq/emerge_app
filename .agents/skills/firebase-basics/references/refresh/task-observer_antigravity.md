# Refresh Task Observer (Antigravity)

Follow these steps to refresh the Task Observer skill in Antigravity.

1. **Check Available Version:**
   ```bash
   npx -y skills add .agents/skills/task-observer --list
   ```

2. **Update the Skill:**
   ```bash
   # Project-level
   npx -y skills update --agent antigravity --yes

   # Global-level (if installed globally)
   npx -y skills update --agent antigravity --global --yes
   ```

3. **Verify Scripts Are Current:**
   ```bash
   python .agents/skills/task-observer/scripts/synthesize.py --review-mode
   ```

4. **Restart Antigravity** to load the updated skill.
