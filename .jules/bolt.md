## 2024-05-22 - [Widget Extraction for Rebuild Optimization]
**Learning:** Extracting a `ConsumerWidget` section into a separate `const` widget prevents it from rebuilding when the parent rebuilds due to unrelated state changes. This is especially impactful for `ListView` or other frequently updating parents.
**Action:** Always check if complex sub-trees (like `WorldView`) in a `ConsumerWidget` depend on the *same* provider as the parent. If not, extract them.
