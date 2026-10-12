$ErrorActionPreference = 'Stop'

$DryRun = $false
$Uninstall = $false
foreach ($arg in $args) {
    switch -Regex ($arg) {
        '^(--dry-run|-DryRun)$' { $DryRun = $true; continue }
        '^(--uninstall|-Uninstall)$' { $Uninstall = $true; continue }
        '^(-h|--help|-Help|/\?)$' {
            Write-Host 'Usage: install.ps1 [--dry-run] [--uninstall]'
            Write-Host '  Installs every skill in this repository for Claude Code and any other agent tool found,'
            Write-Host '  plus the Claude Code helpers, hooks and settings. --dry-run shows the plan and writes'
            Write-Host '  nothing; --uninstall removes the helpers, hooks, their settings and the CLAUDE.md'
            Write-Host '  exemption, and leaves the skills in place.'
            exit 0
        }
        default { Write-Host "Unknown option: $arg (see --help)"; exit 2 }
    }
}

$Repo = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$HomeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { [Environment]::GetFolderPath('UserProfile') }
$Config = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HomeDir '.claude' }
$Backup = Join-Path $Config ('backups\spec-skills\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$Utf8 = New-Object System.Text.UTF8Encoding $false
$TopTier = 'opus|fable|mythos'
$Marker = '**Exempt: the work-orchestrator helpers**'
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

function Write-TextFile([string] $Path, [string] $Text, [string] $Label) {
    if ($DryRun) { return }
    if (Test-Path -LiteralPath $Path) { Backup-File $Path $Label }
    New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
    [IO.File]::WriteAllText($Path, $Text, $Utf8)
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
    (New-Object -ComObject Scripting.FileSystemObject).GetFolder((Resolve-Path -LiteralPath $Path).Path).ShortPath.TrimEnd('\')
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

function ConvertTo-JsonString([string] $Text) {
    $builder = New-Object System.Text.StringBuilder
    [void] $builder.Append('"')
    foreach ($char in $Text.ToCharArray()) {
        switch ($char) {
            '"' { [void] $builder.Append('\"') }
            '\' { [void] $builder.Append('\\') }
            "`n" { [void] $builder.Append('\n') }
            "`r" { [void] $builder.Append('\r') }
            "`t" { [void] $builder.Append('\t') }
            "`b" { [void] $builder.Append('\b') }
            "`f" { [void] $builder.Append('\f') }
            default {
                if ([int] $char -lt 0x20) { [void] $builder.AppendFormat('\u{0:x4}', [int] $char) } else { [void] $builder.Append($char) }
            }
        }
    }
    [void] $builder.Append('"')
    $builder.ToString()
}

function Format-Json($Value, [int] $Level = 0) {
    $pad = '  ' * $Level
    $inner = '  ' * ($Level + 1)
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [bool]) { return $Value.ToString().ToLowerInvariant() }
    if ($Value -is [string]) { return ConvertTo-JsonString $Value }
    if ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal]) {
        return ([IFormattable] $Value).ToString($null, [Globalization.CultureInfo]::InvariantCulture)
    }
    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $members = @($Value.PSObject.Properties | ForEach-Object { "$inner$(ConvertTo-JsonString $_.Name): $(Format-Json $_.Value ($Level + 1))" })
        if ($members.Count -eq 0) { return '{}' }
        return "{`n" + ($members -join ",`n") + "`n$pad}"
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $items = @($Value | ForEach-Object { "$inner$(Format-Json $_ ($Level + 1))" })
        if ($items.Count -eq 0) { return '[]' }
        return "[`n" + ($items -join ",`n") + "`n$pad]"
    }
    return ConvertTo-JsonString ([string] $Value)
}

function Get-Member-Value($Object, [string] $Name) {
    $property = $Object.PSObject.Properties[$Name]
    if ($property) { $property.Value } else { $null }
}

function Set-Member-Value($Object, [string] $Name, $Value) {
    if ($Object.PSObject.Properties[$Name]) { $Object.$Name = $Value } else { $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}

function Test-OurHook($Hook, [string] $Script) {
    ([string] (Get-Member-Value $Hook 'command')).Contains($Script)
}

function Get-LineEnding([string] $Text) {
    if ($Text.Contains("`r`n")) { "`r`n" } else { "`n" }
}

function Merge-Settings($Settings, $HookSpecs) {
    $changes = New-Object System.Collections.Generic.List[string]
    if (-not $Uninstall) {
        $envBlock = Get-Member-Value $Settings 'env'
        if ($null -eq $envBlock) { $envBlock = [pscustomobject] @{}; Set-Member-Value $Settings 'env' $envBlock }
        if ($envBlock.PSObject.Properties['CLAUDE_CODE_SUBAGENT_MODEL_FORCE']) {
            $envBlock.PSObject.Properties.Remove('CLAUDE_CODE_SUBAGENT_MODEL_FORCE')
            $changes.Add('removed CLAUDE_CODE_SUBAGENT_MODEL_FORCE')
        }
        $model = [string] (Get-Member-Value $envBlock 'CLAUDE_CODE_SUBAGENT_MODEL')
        if (-not $model -or $model -match $TopTier) {
            Set-Member-Value $envBlock 'CLAUDE_CODE_SUBAGENT_MODEL' 'claude-sonnet-5-5'
            $changes.Add('set CLAUDE_CODE_SUBAGENT_MODEL to claude-sonnet-5-5')
        }
    }
    foreach ($spec in $HookSpecs) {
        $hooksBlock = Get-Member-Value $Settings 'hooks'
        $entries = @(if ($hooksBlock) { @(Get-Member-Value $hooksBlock $spec.Event) | Where-Object { $null -ne $_ } })
        $desired = [pscustomobject] [ordered] @{
            matcher = $spec.Matcher
            hooks   = @([pscustomobject] [ordered] @{ type = 'command'; command = $spec.Command; timeout = [int] $spec.Timeout })
        }
        $ours = @($entries | Where-Object { @($_.hooks | Where-Object { Test-OurHook $_ $spec.Script }).Count -gt 0 })
        if ($Uninstall -and $ours.Count -eq 0) { continue }
        if (-not $Uninstall -and $ours.Count -eq 1 -and (Format-Json $ours[0]) -eq (Format-Json $desired)) { continue }
        $kept = New-Object System.Collections.Generic.List[object]
        foreach ($entry in $entries) {
            $entryHooks = @($entry.hooks)
            $rest = @($entryHooks | Where-Object { -not (Test-OurHook $_ $spec.Script) })
            if ($rest.Count -eq $entryHooks.Count) { $kept.Add($entry) }
            elseif ($rest.Count -gt 0) { $entry.hooks = $rest; $kept.Add($entry) }
        }
        if (-not $Uninstall) { $kept.Add($desired) }
        $changes.Add($(if ($Uninstall) { "removed the $($spec.Script) $($spec.Event) hook" } else { "set the $($spec.Script) $($spec.Event) hook" }))
        if ($kept.Count -gt 0) {
            if ($null -eq $hooksBlock) { $hooksBlock = [pscustomobject] @{}; Set-Member-Value $Settings 'hooks' $hooksBlock }
            Set-Member-Value $hooksBlock $spec.Event $kept.ToArray()
        } else {
            $hooksBlock.PSObject.Properties.Remove($spec.Event)
            if (@($hooksBlock.PSObject.Properties).Count -eq 0) { $Settings.PSObject.Properties.Remove('hooks') }
        }
    }
    $changes
}

function Get-Exemption([string[]] $Names) {
    $quoted = @($Names | Sort-Object | ForEach-Object { "``$_``" })
    $listed = if ($quoted.Count -gt 1) { ($quoted[0..($quoted.Count - 2)] -join ', ') + ' and ' + $quoted[-1] } else { $quoted[0] }
    $text = "$Marker $([char]0x2014) $listed in ``~/.claude/agents/``. They run on their declared model and effort with " +
        'their output caps; use them without asking. Any other agent, or a change to these definitions, ' +
        'still needs the plan table and a yes.'
    $lines = New-Object System.Collections.Generic.List[string]
    $current = ''
    foreach ($word in $text.Split(' ')) {
        if ($current.Length -eq 0) { $current = $word }
        elseif ($current.Length + 1 + $word.Length -le 100) { $current += " $word" }
        else { $lines.Add($current); $current = $word }
    }
    if ($current) { $lines.Add($current) }
    $lines.ToArray()
}

function Edit-Instructions([string] $Path, [string[]] $HelperNames) {
    if (-not (Test-Path -LiteralPath $Path)) { Report 'unchanged' "$Path - not present"; return }
    $text = [IO.File]::ReadAllText($Path)
    $eol = Get-LineEnding $text
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.AddRange([string[]] ($text -split "`r?`n"))
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i].StartsWith($Marker)) { $start = $i; break } }
    if ($start -ge 0) {
        $end = $start
        while ($end -lt $lines.Count -and $lines[$end].Trim()) { $end++ }
        if ($Uninstall) {
            $first = if ($start -gt 0 -and -not $lines[$start - 1].Trim()) { $start - 1 } else { $start }
            $lines.RemoveRange($first, $end - $first)
            $action = "removed the helpers' exemption"
        } else {
            $wanted = Get-Exemption $HelperNames
            if ((($lines.GetRange($start, $end - $start)) -join "`n") -eq ($wanted -join "`n")) {
                Report 'unchanged' "$Path - exemption already present"; return
            }
            $lines.RemoveRange($start, $end - $start)
            $lines.InsertRange($start, [string[]] $wanted)
            $action = "updated the helpers' exemption"
        }
    } elseif ($Uninstall -or $HelperNames.Count -eq 0) {
        Report 'unchanged' "$Path - no exemption to remove"; return
    } else {
        $heading = -1
        for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^##\s.*ask before launching') { $heading = $i; break } }
        if ($heading -lt 0) { Report 'unchanged' "$Path - no ask-before-subagents rule found"; return }
        $end = $heading + 1
        while ($end -lt $lines.Count -and -not $lines[$end].Trim()) { $end++ }
        while ($end -lt $lines.Count -and $lines[$end].Trim()) { $end++ }
        $lines.InsertRange($end, [string[]] (@('') + (Get-Exemption $HelperNames)))
        $action = "added the helpers' exemption to the ask-before-subagents rule"
    }
    Report 'updated' "$Path - $action"
    Write-TextFile $Path ($lines.ToArray() -join $eol) 'claude\CLAUDE.md'
}

$mode = if ($Uninstall) { 'uninstall' } else { 'install' }
if ($DryRun) { Write-Host "spec-skills $mode - dry run, nothing written ($Config)" } else { Write-Host "spec-skills $mode ($Config)" }

$settingsPath = Join-Path $Config 'settings.json'
$settingsText = if (Test-Path -LiteralPath $settingsPath) { [IO.File]::ReadAllText($settingsPath) } else { '' }
try {
    $settings = if ($settingsText.Trim()) { $settingsText | ConvertFrom-Json } else { [pscustomobject] @{} }
} catch {
    Write-Host "$settingsPath is not valid JSON; fix it, then run this again. Nothing was changed."
    exit 1
}

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
$helpers = @($skillNames | ForEach-Object {
    Get-ChildItem -LiteralPath (Join-Path $Repo "$_\claude-code\agents") -Filter '*.md' -File -ErrorAction SilentlyContinue
} | Sort-Object Name)
$helperNames = @($helpers | ForEach-Object { $_.BaseName })

if (-not $Uninstall) {
    Write-Host 'Skills'
    $targets = @([pscustomobject] @{ Path = (Join-Path $Config 'skills'); Label = 'claude-skills' })
    if ((Test-Path (Join-Path $HomeDir '.codex')) -or (Test-Path (Join-Path $HomeDir '.cursor')) -or (Test-Path (Join-Path $HomeDir '.gemini'))) {
        $targets += [pscustomobject] @{ Path = (Join-Path $HomeDir '.agents\skills'); Label = 'agents-skills' }
    }
    if (Test-Path (Join-Path $HomeDir '.copilot')) {
        $targets += [pscustomobject] @{ Path = (Join-Path $HomeDir '.copilot\skills'); Label = 'copilot-skills' }
    }
    foreach ($target in $targets) {
        if (Test-SameDir $Repo $target.Path) {
            Report 'skipped' "$($target.Path) - this repository is that folder; a git pull keeps it current"
            continue
        }
        foreach ($skill in $skillNames) {
            Sync-Skill (Join-Path $Repo $skill) (Join-Path $target.Path $skill) (Join-Path $target.Label $skill)
        }
    }
}

Write-Host 'Claude Code helpers'
foreach ($helper in $helpers) {
    $target = Join-Path $Config "agents\$($helper.Name)"
    $label = "claude\agents\$($helper.Name)"
    if ($Uninstall) { Remove-InstalledFile $target $label } else { Put-File $helper.FullName $target $label }
}

Write-Host 'Claude Code hooks'
$hookSpecs = New-Object System.Collections.Generic.List[object]
foreach ($skill in $skillNames) {
    $list = Join-Path $Repo "$skill\claude-code\hooks.list"
    if (-not (Test-Path -LiteralPath $list)) { continue }
    $hookDir = Join-Path $Repo "$skill\claude-code\hooks"
    foreach ($line in [IO.File]::ReadAllLines($list)) {
        $parts = @($line.Trim() -split '\s+' | Where-Object { $_ })
        if ($parts.Count -lt 4) { continue }
        $script = $parts[2]
        $target = Join-Path $Config "hooks\$script.ps1"
        $allowTarget = Join-Path $Config "hooks\$script.allow"
        Get-ChildItem -Path (Join-Path $Config "hooks\$script.*") -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne "$script.ps1" -and $_.Name -ne "$script.allow" } |
            ForEach-Object { Remove-InstalledFile $_.FullName "claude\hooks\$($_.Name)" }
        if ($Uninstall) {
            Remove-InstalledFile $target "claude\hooks\$script.ps1"
            Remove-InstalledFile $allowTarget "claude\hooks\$script.allow"
        } else {
            Put-File (Join-Path $hookDir "$script.ps1") $target "claude\hooks\$script.ps1"
            $allowSource = Join-Path $hookDir "$script.allow"
            if (Test-Path -LiteralPath $allowSource) {
                $allowLines = @([IO.File]::ReadAllLines($allowSource) | Where-Object { $_.Trim() }) + $helperNames
                $temp = [IO.Path]::GetTempFileName()
                [IO.File]::WriteAllText($temp, (($allowLines -join "`n") + "`n"), $Utf8)
                Put-File $temp $allowTarget "claude\hooks\$script.allow"
                Remove-Item -LiteralPath $temp -Force
            }
        }
        $command = 'powershell -NoProfile -ExecutionPolicy Bypass -File "' + $target.Replace('\', '/') + '"'
        $hookSpecs.Add([pscustomobject] @{ Event = $parts[0]; Matcher = $parts[1]; Script = $script; Timeout = $parts[3]; Command = $command })
    }
}

Write-Host 'Claude Code settings and instructions'
$changes = @(Merge-Settings $settings $hookSpecs)
if ($changes.Count -gt 0) {
    Report 'updated' "$settingsPath - $($changes -join '; ')"
    $eol = if ($settingsText) { Get-LineEnding $settingsText } else { "`n" }
    Write-TextFile $settingsPath (((Format-Json $settings) -replace "`n", $eol) + $eol) 'claude\settings.json'
} else {
    Report 'unchanged' $settingsPath
}
Edit-Instructions (Join-Path $Config 'CLAUDE.md') $helperNames

Write-Host ''
if ($DryRun) {
    Write-Host 'Dry run: nothing was written.'
} elseif ($script:Changed) {
    Write-Host "Done. Replaced and removed files are backed up in $Backup."
    Write-Host 'Start a new Claude Code session so the helpers, hooks and settings load.'
} else {
    Write-Host 'Already up to date; nothing changed.'
}
exit 0
