# codex-smart

Auto-retry and task splitting wrapper for [OpenAI Codex CLI](https://github.com/openai/codex).

## The Problem

Codex CLI frequently fails mid-session with:

```
■ stream disconnected before completion: response.failed event received
```

This is a [known issue](https://github.com/openai/codex/issues/8865) with no official fix yet.

On top of that, long coding sessions fill up the context window quickly, causing compaction errors and degraded performance.

## The Solution

`codex-smart.ps1` solves both problems:

1. **Auto-retry** on stream disconnects — no more typing "continue" manually
2. **Task splitting** — breaks large jobs into small, focused sessions that don't overflow the context window
3. **Fully autonomous** — runs in `exec --full-auto` mode, no confirmations needed

Each task runs as a fresh Codex session. Since Codex reads files from disk, it sees changes from previous tasks automatically. No context is wasted carrying forward conversation history.

## Setup

### Prerequisites

- [Codex CLI](https://github.com/openai/codex) installed (`npm install -g @openai/codex`)
- PowerShell 5.1+ (included with Windows)
- A configured `~/.codex/config.toml` (any provider — OpenAI, Azure, etc.)

## Usage

### 1. Create a tasks file

Create `tasks.md` in your project root. Each line is one task:

```markdown
# .NET Framework to .NET 8 Migration
Convert MyProject.csproj from old format to SDK-style targeting net8.0
Migrate web.config settings to appsettings.json
Replace Startup.cs with Program.cs minimal hosting pattern
Migrate Services/PaymentService.cs to .NET 8 APIs
Migrate Controllers/ApiController.cs to .NET 8 controller pattern
Run dotnet build and fix all compilation errors
Run dotnet test and fix all failing tests
```

Lines starting with `#` are comments. Empty lines are skipped.

**Tip:** Let Codex generate the task list for you:

```powershell
codex "Analyze this solution. Create a tasks.md with remaining migration tasks, one per line."
```

### 2. Run

```powershell
.\codex-smart.ps1 -TaskFile tasks.md
```

Or with the default `tasks.md`:

```powershell
.\codex-smart.ps1
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-TaskFile` | `tasks.md` | Path to the task list file |
| `-MaxRetries` | `5` | Max retry attempts per task on stream disconnect |
| `-RetryDelay` | `5` | Seconds to wait between retries |
| `-TaskDelay` | `3` | Seconds to wait between tasks |

## How it works

```
tasks.md          codex-smart.ps1         Codex CLI
┌──────────┐      ┌──────────────┐      ┌──────────────┐
│ Task 1   │─────>│ exec task 1  │─────>│ Fresh session │
│ Task 2   │      │   retry if   │      │ Reads disk    │
│ Task 3   │      │   disconnect │      │ Edits files   │
│ ...      │      │ exec task 2  │─────>│ Fresh session │
└──────────┘      │   ...        │      │ Sees changes  │
                  └──────────────┘      └──────────────┘
```

Each task gets a clean context window. Codex reads the current state of files from disk, so it picks up changes from previous tasks without needing conversation history.

## Tips

- **Be specific in tasks** — "Migrate Services/PaymentService.cs to .NET 8" works better than "migrate the services"
- **One file per task** for large migrations — keeps context small
- **Add a `.codexignore`** to skip bin/obj/packages/node_modules
- **Add an `AGENTS.md`** with project-specific instructions that persist across sessions
- **Order tasks by dependency** — foundational changes first, then individual files, build fix last
- **Review changes** with `git diff` after the run — the script doesn't verify task success beyond stream errors

## Known Limitations

- Stream disconnects are a server-side issue, not fixable client-side. This script automates the retry.
- The script doesn't verify if a task completed successfully — it checks for stream disconnects only.
- Failed tasks are listed at the end so you can re-run them.

## Related Issues

- [openai/codex#8865](https://github.com/openai/codex/issues/8865) — Stream disconnect
- [openai/codex#9936](https://github.com/openai/codex/issues/9936) — Stream disconnect (Windows)
- [openai/codex#9995](https://github.com/openai/codex/issues/9995) — Stream closed before response.completed

## License

MIT
