# Branching Strategy & Workflow

This project follows a **Short-lived Feature Branch** strategy. The goal is to maintain a stable `main` branch while allowing rapid, parallel development with high-quality standards.

## 1. Branch Hierarchy

### Long-Lived Branches
*   **`main`**: The source of truth. Every commit on `main` must be "green" (builds successfully and passes all CI checks). Direct pushes to `main` are blocked.

### Short-Lived Branches (Ephemeral)
*   **`feature/*`**: For new functional features or improvements.
*   **`bugfix/*`**: For resolving bugs found in development/staging.
*   **`chore/*`**: For maintenance tasks that do not modify application logic (e.g., dependency updates, CI/CD scripts, or linting rules).
*   **`hotfix/*`**: For urgent production issues requiring immediate patching.
*   **`release/*`**: Temporary branches for final version stabilization and Store submission.

---

## 2. Naming Conventions

All branches must follow the `<type>/<ticket-id>-<brief-description>` pattern:

