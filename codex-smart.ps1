# codex-smart.ps1
# Auto-retry and task splitting wrapper for Codex CLI on Azure OpenAI.
# Solves stream disconnect errors and context window overflow.
# https://github.com/openai/codex/issues/8865

param(
    [string]$TaskFile = "tasks.md",
    [int]$MaxRetries = 5,
    [int]$RetryDelay = 5,
    [int]$TaskDelay = 3
)

if (-not (Test-Path $TaskFile)) {
    Write-Host "Task file not found: $TaskFile" -ForegroundColor Red
    exit 1
}

$tasks = Get-Content $TaskFile | Where-Object { $_.Trim() -ne "" -and $_ -notmatch "^#" }

if ($tasks.Count -eq 0) {
    Write-Host "No tasks found in $TaskFile" -ForegroundColor Yellow
    exit 0
}

Write-Host "`ncodex-smart: $($tasks.Count) tasks loaded from $TaskFile`n" -ForegroundColor Green

$taskIndex = 0
$failed = @()

foreach ($task in $tasks) {
    $taskIndex++
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "[$taskIndex/$($tasks.Count)] $task" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    $retries = 0
    $success = $false

    while ($retries -lt $MaxRetries) {
        $output = codex exec --full-auto $task 2>&1 | Out-String

        if ($output -match "stream disconnected") {
            $retries++
            Write-Host "Stream disconnect #$retries/$MaxRetries. Retry in ${RetryDelay}s..." -ForegroundColor Yellow
            Start-Sleep -Seconds $RetryDelay
            continue
        }

        $success = $true
        break
    }

    if (-not $success) {
        Write-Host "Task failed after $MaxRetries retries: $task" -ForegroundColor Red
        $failed += $task
    }

    if ($taskIndex -lt $tasks.Count) {
        Write-Host "Next task in ${TaskDelay}s..." -ForegroundColor Gray
        Start-Sleep -Seconds $TaskDelay
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Done: $($tasks.Count - $failed.Count)/$($tasks.Count) tasks completed." -ForegroundColor Green

if ($failed.Count -gt 0) {
    Write-Host "`nFailed tasks:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host "`nRe-run failed tasks by adding them to a new tasks file." -ForegroundColor Yellow
}
