$ErrorActionPreference = 'Stop'

$DryRun = $false
$Uninstall = $false
$Requested = New-Object System.Collections.Generic.List[string]
foreach ($arg in $args) {
    switch -Regex ($arg) {
        '^(--dry-run|-DryRun)$' { $DryRun = $true; continue }
        '^(--uninstall|-Uninstall)$' { $Uninstall = $true; continue }
        '^(-h|--help|-Help|/\?)$' {
            Write-Host 'Usage: install.ps1 [--dry-run] [--uninstall] [skill ...]'
            Write-Host '  Installs the named skills - every skill in this repository when none is named - for'
            Write-Host '  Claude Code and any other agent tool found. A skill that another one links into is'
            Write-Host '  installed with it.'
            Write-Host '  --uninstall removes the named skills - every one of them that is installed when none is'
            Write-Host '  named.'
            Write-Host '  --dry-run shows the plan and writes nothing.'
            exit 0
        }
        '^-' { Write-Host "Unknown option: $_ (see --help)"; exit 2 }
        default {
            foreach ($name in ([string] $_).Split(',')) {
                $name = $name.Trim().TrimEnd('/', '\')
                if ($name) { $Requested.Add($name) }
            }
        }
    }
}

$Repo = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$HomeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { [Environment]::GetFolderPath('UserProfile') }
$Config = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HomeDir '.claude' }
$Backup = Join-Path $Config ('backups\spec-skills\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$script:Changed = $false

function Report([string] $Status, [string] $What) {
    Write-Host ('  {0,-9} {1}' -f $Status, $What)
    if ('added', 'updated', 'removed' -contains $Status) { $script:Changed = $true }
}

function Backup-File([string] $Path, [string] $Label) {
    $target = Join-Path $Backup $Label
    New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
    Copy-Item -LiteralPath $Path -Destination $target -Force
}

function Test-SameFile([string] $A, [string] $B) {
    (Test-Path -LiteralPath $B) -and ((Get-FileHash -LiteralPath $A).Hash -eq (Get-FileHash -LiteralPath $B).Hash)
}

function Put-File([string] $Source, [string] $Target, [string] $Label) {
    if (Test-SameFile $Source $Target) { Report 'unchanged' $Target; return }
    Report $(if (Test-Path -LiteralPath $Target) { 'updated' } else { 'added' }) $Target
    if ($DryRun) { return }
    if (Test-Path -LiteralPath $Target) { Backup-File $Target $Label }
    New-Item -ItemType Directory -Force -Path (Split-Path $Target) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Target -Force
}

function Remove-InstalledFile([string] $Path, [string] $Label) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    Report 'removed' $Path
    if ($DryRun) { return }
    Backup-File $Path $Label
    Remove-Item -LiteralPath $Path -Force
}

function Get-CanonicalPath([string] $Path) {
    $item = Get-Item -LiteralPath $Path -Force
    for ($hop = 0; $hop -lt 8 -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint); $hop++) {
        $link = [string] @($item.Target)[0]
        if (-not $link) { break }
        if (-not [IO.Path]::IsPathRooted($link)) { $link = Join-Path (Split-Path $item.FullName) $link }
        $item = Get-Item -LiteralPath $link -Force
    }
    (New-Object -ComObject Scripting.FileSystemObject).GetFolder($item.FullName).ShortPath.TrimEnd('\')
}

function Test-SameDir([string] $A, [string] $B) {
    (Test-Path -LiteralPath $A -PathType Container) -and (Test-Path -LiteralPath $B -PathType Container) -and
    ((Get-CanonicalPath $A) -eq (Get-CanonicalPath $B))
}

function Sync-Skill([string] $Source, [string] $Target, [string] $Label) {
    foreach ($rel in @(Get-ChildItem -LiteralPath $Source -Recurse -File -Name | Sort-Object)) {
        Put-File (Join-Path $Source $rel) (Join-Path $Target $rel) (Join-Path $Label $rel)
    }
    if (-not (Test-Path -LiteralPath $Target)) { return }
    foreach ($rel in @(Get-ChildItem -LiteralPath $Target -Recurse -File -Name | Sort-Object)) {
        if (-not (Test-Path -LiteralPath (Join-Path $Source $rel))) {
            Remove-InstalledFile (Join-Path $Target $rel) (Join-Path $Label $rel)
        }
    }
}

function Unsync-Skill([string] $Target, [string] $Label) {
    if (-not (Test-Path -LiteralPath $Target -PathType Container)) { return }
    foreach ($rel in @(Get-ChildItem -LiteralPath $Target -Recurse -File -Force -Name | Sort-Object)) {
        Remove-InstalledFile (Join-Path $Target $rel) (Join-Path $Label $rel)
    }
    if (-not $DryRun) { Remove-Item -LiteralPath $Target -Recurse -Force }
}

function Get-LinkedSkills([string] $Skill) {
    $found = @(Get-ChildItem -LiteralPath (Join-Path $Repo $Skill) -Recurse -File |
        Select-String -Pattern '\.\./([A-Za-z0-9._-]+)/' -AllMatches |
        ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value })
    @($found | Sort-Object -Unique | Where-Object { $_ -ne $Skill -and $skillNames -ccontains $_ })
}

$mode = if ($Uninstall) { 'uninstall' } else { 'install' }
if ($DryRun) { Write-Host "spec-skills $mode - dry run, nothing written ($Config)" } else { Write-Host "spec-skills $mode ($Config)" }

$skillNames = @()
if (Test-Path -LiteralPath (Join-Path $Repo '.git')) {
    try {
        $skillNames = @(git -C $Repo ls-files 2>$null | Where-Object { $_ -match '^[^/]+/SKILL\.md$' } | ForEach-Object { $_.Split('/')[0] })
    } catch {
        $skillNames = @()
    }
}
if ($skillNames.Count -eq 0) {
    $skillNames = @(Get-ChildItem -LiteralPath $Repo -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object { $_.Name })
}
$skillNames = @($skillNames | Sort-Object -Unique)

foreach ($name in $Requested) {
    if ($skillNames -cnotcontains $name) {
        Write-Host "Unknown skill: $name. Skills in this repository: $($skillNames -join ' ')"
        exit 2
    }
}
$selected = New-Object System.Collections.Generic.List[string]
foreach ($name in $(if ($Requested.Count) { $Requested } else { $skillNames })) {
    if (-not $selected.Contains($name)) { $selected.Add($name) }
}

$claudeSkills = [pscustomobject] @{ Path = (Join-Path $Config 'skills'); Label = 'claude-skills' }
$agentsSkills = [pscustomobject] @{ Path = (Join-Path $HomeDir '.agents\skills'); Label = 'agents-skills' }
$copilotSkills = [pscustomobject] @{ Path = (Join-Path $HomeDir '.copilot\skills'); Label = 'copilot-skills' }
if ($Uninstall) {
    $targets = @($claudeSkills, $agentsSkills, $copilotSkills)
} else {
    $targets = @($claudeSkills)
    if ((Test-Path (Join-Path $HomeDir '.codex')) -or (Test-Path (Join-Path $HomeDir '.cursor')) -or (Test-Path (Join-Path $HomeDir '.gemini'))) {
        $targets += $agentsSkills
    }
    if (Test-Path (Join-Path $HomeDir '.copilot')) { $targets += $copilotSkills }
}

$notes = New-Object System.Collections.Generic.List[string]
if ($Uninstall) {
    foreach ($skill in $skillNames) {
        if ($selected.Contains($skill)) { continue }
        foreach ($target in $targets) {
            if (Test-SameDir $Repo $target.Path) { continue }
            if (-not (Test-Path -LiteralPath (Join-Path $target.Path "$skill\SKILL.md"))) { continue }
            foreach ($needed in (Get-LinkedSkills $skill)) {
                if ($selected.Contains($needed)) {
                    Write-Host "$skill in $($target.Path) links into $needed, so $needed stays. Uninstall $skill with it, or leave $needed out. Nothing was changed."
                    exit 1
                }
            }
        }
    }
} else {
    for ($index = 0; $index -lt $selected.Count; $index++) {
        foreach ($needed in (Get-LinkedSkills $selected[$index])) {
            if (-not $selected.Contains($needed)) {
                $selected.Add($needed)
                $notes.Add("$needed is included: $($selected[$index]) links into it")
            }
        }
    }
}

Write-Host "Skills: $($selected -join ' ')"
foreach ($note in $notes) { Write-Host "  $note" }
foreach ($target in $targets) {
    if ($Uninstall -and -not (Test-Path -LiteralPath $target.Path -PathType Container)) { continue }
    if (Test-SameDir $Repo $target.Path) {
        Report 'skipped' "$($target.Path) - this repository is that folder; a git pull keeps it current"
        continue
    }
    foreach ($skill in $selected) {
        $source = Join-Path $Repo $skill
        $destination = Join-Path $target.Path $skill
        $label = Join-Path $target.Label $skill
        $item = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            Report 'skipped' "$destination - a link, left as it is"
            continue
        }
        if ($Uninstall) { Unsync-Skill $destination $label } else { Sync-Skill $source $destination $label }
    }
}

Write-Host ''
if ($DryRun) {
    Write-Host 'Dry run: nothing was written.'
} elseif ($script:Changed) {
    Write-Host "Done. Replaced and removed files are backed up in $Backup."
    Write-Host 'Start a new session in your agent tool so the skills load.'
} else {
    Write-Host 'Already up to date; nothing changed.'
}
exit 0
