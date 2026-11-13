---
name: slim-changes
description: Use during software changes when deciding whether to add files, extract helpers, add documentation, or restructure code. Prefer small, readable changes in existing files.
---

# Slim changes

- Start with the existing file that naturally owns the behavior. Keep related logic there when it remains easy to read.
- Create a new file only when it has a clear independent responsibility, is required by the tool or framework, or materially improves readability or reuse. Do not split code merely to make a diff look organized.
- Keep the number of changed files and the scope of edits as small as practical. Avoid incidental wrappers, barrel files, placeholder files, and unrequested documentation.
- Preserve correctness and readability. If a new file is justified, explain its purpose in the handoff.
