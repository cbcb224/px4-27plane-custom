[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:FailureCount = 0
$script:WarningCount = 0

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Write-Check {
    param(
        [ValidateSet('PASS', 'WARN', 'FAIL', 'INFO')]
        [string]$Status,
        [string]$Message
    )

    $color = switch ($Status) {
        'PASS' { 'Green' }
        'WARN' { 'Yellow' }
        'FAIL' { 'Red' }
        default { 'Gray' }
    }

    if ($Status -eq 'FAIL') {
        $script:FailureCount++
    }
    elseif ($Status -eq 'WARN') {
        $script:WarningCount++
    }

    Write-Host ("[{0}] {1}" -f $Status, $Message) -ForegroundColor $color
}

function Invoke-Git {
    param([string[]]$GitArguments)

    $output = @(& git -C $script:RepoRoot @GitArguments 2>$null)
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

function Get-WorkflowValue {
    param(
        [string[]]$Lines,
        [string]$Name
    )

    $pattern = '^\s*' + [regex]::Escape($Name) + '\s*:'
    $line = @($Lines | Where-Object { $_ -match $pattern } | Select-Object -First 1)
    if ($line.Count -eq 0) {
        return $null
    }

    $value = ($line[0] -replace $pattern, '').Trim()
    if ($value -match '^"(.*)"$') {
        return $Matches[1].Trim()
    }
    if ($value -match "^'(.*)'$") {
        return $Matches[1].Trim()
    }

    return (($value -split '\s+#', 2)[0]).Trim()
}

try {
    $resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot -ErrorAction Stop).Path.TrimEnd([char[]]@('\', '/'))
}
catch {
    Write-Check 'FAIL' "源码目录不存在：$RepoRoot"
    exit 1
}

$script:RepoRoot = $resolvedRoot

Write-Host 'PX4 GitHub 云编译准备只读检查' -ForegroundColor White
Write-Host "时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
Write-Host "检查目录：$resolvedRoot"

Write-Section 'PX4 源码根目录'
$requiredMarkers = @('Makefile', 'boards', 'platforms', '.gitmodules')
$missingMarkers = @($requiredMarkers | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $resolvedRoot $_) -ErrorAction SilentlyContinue)
})

if ($missingMarkers.Count -gt 0) {
    Write-Check 'FAIL' "不是完整的 PX4 源码根目录，缺少：$($missingMarkers -join ', ')"
    exit 1
}
Write-Check 'PASS' 'PX4 源码根目录标记文件完整。'

if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Check 'FAIL' 'Git 不可用。Windows 至少需要 Git 来完成提交和推送。'
    exit 1
}

$gitVersion = @(& git --version 2>$null)
if ($LASTEXITCODE -eq 0 -and $gitVersion.Count -gt 0) {
    Write-Check 'PASS' "Git 可用：$($gitVersion[0])"
}
else {
    Write-Check 'FAIL' 'Git 版本检查失败。'
    exit 1
}

Write-Section 'Git 版本与工作树'
$gitRootResult = Invoke-Git @('rev-parse', '--show-toplevel')
if ($gitRootResult.ExitCode -ne 0 -or $gitRootResult.Output.Count -eq 0) {
    Write-Check 'FAIL' '无法读取 Git 仓库根目录。'
    exit 1
}

$gitRoot = [System.IO.Path]::GetFullPath(([string]$gitRootResult.Output[0])).TrimEnd([char[]]@('\', '/'))
if ([System.StringComparer]::OrdinalIgnoreCase.Equals($gitRoot, $resolvedRoot)) {
    Write-Check 'PASS' "Git 仓库根目录：$gitRoot"
}
else {
    Write-Check 'WARN' "Git 仓库根目录与检查目录不同：$gitRoot"
}

$branchResult = Invoke-Git @('branch', '--show-current')
$branch = if ($branchResult.ExitCode -eq 0 -and $branchResult.Output.Count -gt 0) {
    [string]$branchResult.Output[0]
}
else {
    '(detached)'
}

$commitResult = Invoke-Git @('rev-parse', 'HEAD')
$commit = if ($commitResult.ExitCode -eq 0 -and $commitResult.Output.Count -gt 0) {
    [string]$commitResult.Output[0]
}
else {
    'unknown'
}

$exactTagResult = Invoke-Git @('describe', '--tags', '--exact-match')
$exactTag = if ($exactTagResult.ExitCode -eq 0 -and $exactTagResult.Output.Count -gt 0) {
    [string]$exactTagResult.Output[0]
}
else {
    '(none)'
}

$describeResult = Invoke-Git @('describe', '--tags', '--always', '--long')
$description = if ($describeResult.ExitCode -eq 0 -and $describeResult.Output.Count -gt 0) {
    [string]$describeResult.Output[0]
}
else {
    'unknown'
}

Write-Host "分支：$branch"
Write-Host "提交：$commit"
Write-Host "精确标签：$exactTag"
Write-Host "版本描述：$description"

if ($exactTag -eq 'v1.16.2') {
    Write-Check 'PASS' '当前提交精确位于 PX4 v1.16.2。'
}
elseif ($description -match '^v1\.16\.2(?:-|$)') {
    Write-Check 'WARN' "当前提交基于 v1.16.2，但已有后续提交：$description"
}
else {
    Write-Check 'WARN' "当前提交没有直接落在 v1.16.2：$description"
}

if ($branch -eq '(detached)') {
    Write-Check 'WARN' '当前处于 detached HEAD；应在自己的开发分支上修改和提交。'
}
else {
    Write-Check 'PASS' "当前开发分支：$branch"
}

$statusResult = Invoke-Git @('status', '--short', '--untracked-files=normal')
$statusLines = @($statusResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
if ($statusLines.Count -eq 0) {
    Write-Check 'PASS' '工作树干净。'
}
else {
    Write-Check 'WARN' "工作树有 $($statusLines.Count) 项未提交内容；云编译只会使用已经推送的提交。"
    $statusLines | Select-Object -First 20 | ForEach-Object {
        Write-Host "       $_" -ForegroundColor DarkGray
    }
    if ($statusLines.Count -gt 20) {
        Write-Host "       ... 其余 $($statusLines.Count - 20) 项省略" -ForegroundColor DarkGray
    }
}

Write-Section '子模块完整性'
$submoduleResult = Invoke-Git @('submodule', 'status', '--recursive')
if ($submoduleResult.ExitCode -ne 0) {
    Write-Check 'FAIL' '无法读取子模块状态。'
}
else {
    $submoduleLines = @($submoduleResult.Output)
    $missingSubmodules = @($submoduleLines | Where-Object { [string]$_ -match '^-' })
    $mismatchedSubmodules = @($submoduleLines | Where-Object { [string]$_ -match '^\+' })

    Write-Host "递归子模块数量：$($submoduleLines.Count)"
    if ($missingSubmodules.Count -gt 0) {
        Write-Check 'FAIL' "$($missingSubmodules.Count) 个子模块未初始化；推送前先执行 git submodule update --init --recursive。"
    }
    elseif ($mismatchedSubmodules.Count -gt 0) {
        Write-Check 'WARN' "$($mismatchedSubmodules.Count) 个子模块提交与父仓库记录不同；确认这是有意修改。"
    }
    else {
        Write-Check 'PASS' '所有子模块均已初始化，且提交与父仓库记录一致。'
    }
}

Write-Section '板卡目标与 board ID'
$boardFiles = @(Get-ChildItem -LiteralPath (Join-Path $resolvedRoot 'boards') -Recurse -Filter '*.px4board' -File)
$targets = @(
    foreach ($file in $boardFiles) {
        $relative = $file.FullName.Substring($resolvedRoot.Length + 1)
        $parts = @($relative -split '[\\/]')
        if ($parts.Count -eq 4 -and $parts[0] -eq 'boards') {
            $label = [System.IO.Path]::GetFileNameWithoutExtension($parts[3])
            '{0}_{1}_{2}' -f $parts[1], $parts[2], $label
        }
    }
) | Sort-Object -Unique

Write-Host "*.px4board 文件：$($boardFiles.Count)"
Write-Host "唯一云构建目标：$($targets.Count)"
if ($boardFiles.Count -gt 0 -and $targets.Count -gt 0) {
    Write-Check 'PASS' '可以从 boards/<vendor>/<model>/<label>.px4board 生成构建目标。'
}
else {
    Write-Check 'FAIL' '没有发现可用的 PX4 板卡目标。'
}

$prototypeFiles = @(Get-ChildItem -LiteralPath (Join-Path $resolvedRoot 'boards') -Recurse -Filter 'firmware.prototype' -File)
$boardIdRecords = New-Object System.Collections.Generic.List[object]
foreach ($prototype in $prototypeFiles) {
    try {
        $json = Get-Content -LiteralPath $prototype.FullName -Raw | ConvertFrom-Json
        if ($null -eq $json.board_id) {
            throw '缺少 board_id'
        }
        $relative = $prototype.FullName.Substring($resolvedRoot.Length + 1)
        $null = $boardIdRecords.Add([pscustomobject]@{
            BoardId = [int64]$json.board_id
            File    = $relative
        })
    }
    catch {
        Write-Check 'WARN' "无法解析 $($prototype.FullName)：$($_.Exception.Message)"
    }
}

$boardIds = @($boardIdRecords | ForEach-Object { [int64]$_.BoardId })
$uniqueBoardIds = @($boardIds | Sort-Object -Unique)
Write-Host "firmware.prototype：$($prototypeFiles.Count)"
Write-Host "唯一 board ID：$($uniqueBoardIds.Count)"
if ($uniqueBoardIds.Count -gt 0) {
    Write-Host "最大 board ID：$(($uniqueBoardIds | Measure-Object -Maximum).Maximum)"
}

$duplicateGroups = @($boardIds | Group-Object | Where-Object { $_.Count -gt 1 })
if ($duplicateGroups.Count -eq 0) {
    Write-Check 'PASS' '当前源码树内没有发现重复 board ID。'
}
else {
    $duplicateSummary = ($duplicateGroups | Sort-Object { [int64]$_.Name } | Select-Object -First 8 | ForEach-Object {
        "$($_.Name) x$($_.Count)"
    }) -join ', '
    Write-Check 'WARN' "发现 $($duplicateGroups.Count) 个重复 board ID（$duplicateSummary）。变体复用可能合法；自定义新 ID 仍必须查重。"
}

Write-Section 'GitHub Actions 工作流'
$templatePath = Join-Path $resolvedRoot '.codex\github-actions\px4-custom-board.yml'
$installedWorkflowPath = Join-Path $resolvedRoot '.github\workflows\px4-custom-board.yml'
$workflowPaths = New-Object System.Collections.Generic.List[string]

if (Test-Path -LiteralPath $templatePath -PathType Leaf) {
    Write-Check 'PASS' '云编译工作流模板存在。'
    $null = $workflowPaths.Add($templatePath)
}
else {
    Write-Check 'FAIL' "缺少工作流模板：$templatePath"
}

if (Test-Path -LiteralPath $installedWorkflowPath -PathType Leaf) {
    Write-Check 'PASS' '仓库已安装 .github/workflows/px4-custom-board.yml。'
    $null = $workflowPaths.Add($installedWorkflowPath)
}
else {
    Write-Check 'WARN' '仓库尚未安装 .github/workflows/px4-custom-board.yml；推送后不会自动云编译。'
}

foreach ($workflowPath in $workflowPaths) {
    $workflowLines = @(Get-Content -LiteralPath $workflowPath)
    $workflowName = $workflowPath.Substring($resolvedRoot.Length + 1)
    $target = Get-WorkflowValue -Lines $workflowLines -Name 'PX4_BOARD_TARGET'
    if ([string]::IsNullOrWhiteSpace($target)) {
        Write-Check 'FAIL' "$workflowName 未配置 PX4_BOARD_TARGET。"
    }
    elseif ($targets -contains $target) {
        Write-Check 'PASS' "$workflowName 的应用程序目标存在：$target"
    }
    else {
        Write-Check 'FAIL' "$workflowName 的应用程序目标不存在：$target"
    }

    $buildBootloader = Get-WorkflowValue -Lines $workflowLines -Name 'PX4_BUILD_BOOTLOADER'
    if ($buildBootloader -eq 'true') {
        $bootloaderTarget = Get-WorkflowValue -Lines $workflowLines -Name 'PX4_BOOTLOADER_TARGET'
        if ([string]::IsNullOrWhiteSpace($bootloaderTarget)) {
            Write-Check 'FAIL' "$workflowName 开启了 bootloader 构建，但未配置 PX4_BOOTLOADER_TARGET。"
        }
        elseif ($targets -contains $bootloaderTarget) {
            Write-Check 'PASS' "$workflowName 的 bootloader 目标存在：$bootloaderTarget"
        }
        else {
            Write-Check 'FAIL' "$workflowName 的 bootloader 目标不存在：$bootloaderTarget"
        }
    }
    else {
        Write-Check 'INFO' "$workflowName 当前未开启 bootloader 云编译。"
    }
}

Write-Section 'Git remote'
$remoteResult = Invoke-Git @('remote')
$remotes = @($remoteResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
if ($remotes.Count -eq 0) {
    Write-Check 'FAIL' '没有配置 Git remote，无法推送源码到 GitHub Actions。'
}
else {
    Write-Host "remote：$($remotes -join ', ')"
    if ($remotes -contains 'origin') {
        $originUrlResult = Invoke-Git @('remote', 'get-url', 'origin')
        if ($originUrlResult.ExitCode -eq 0 -and $originUrlResult.Output.Count -gt 0) {
            $originUrl = [string]$originUrlResult.Output[0]
            if ($originUrl -match 'github\.com[/:]PX4/PX4-Autopilot(?:\.git)?/?$') {
                Write-Check 'PASS' 'origin 仍指向官方 PX4/PX4-Autopilot。'
            }
            else {
                Write-Check 'INFO' 'origin 不是官方 PX4 地址；请确认它的推送目标。'
            }
        }
    }

    $customRemotes = @($remotes | Where-Object { $_ -ne 'origin' })
    if ($customRemotes.Count -gt 0) {
        Write-Check 'PASS' "已配置自定义 remote：$($customRemotes -join ', ')"
    }
    else {
        Write-Check 'WARN' '尚未配置自己的 GitHub remote；不能把自定义分支推送到自己的仓库。'
    }
}

Write-Section '磁盘空间'
$driveQualifier = Split-Path -Qualifier $resolvedRoot
if (-not [string]::IsNullOrWhiteSpace($driveQualifier)) {
    $driveName = $driveQualifier.TrimEnd(':')
    $drive = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue
    if ($null -ne $drive -and $null -ne $drive.Free) {
        $freeGiB = [math]::Round($drive.Free / 1GB, 2)
        if ($freeGiB -ge 10) {
            Write-Check 'PASS' "${driveQualifier} 可用空间：$freeGiB GiB"
        }
        elseif ($freeGiB -ge 5) {
            Write-Check 'WARN' "${driveQualifier} 可用空间偏低：$freeGiB GiB"
        }
        else {
            Write-Check 'FAIL' "${driveQualifier} 可用空间不足：$freeGiB GiB"
        }
    }
    else {
        Write-Check 'WARN' "无法读取 ${driveQualifier} 的可用空间。"
    }
}

Write-Section '结论'
Write-Check 'INFO' 'GitHub Actions 云编译不需要本地 WSL、Docker Desktop、CMake、ARM 交叉编译器或 make。'
Write-Check 'INFO' '推送前确认 commit、子模块、工作流文件和目标名都已进入同一个提交。'
Write-Check 'INFO' '云编译不验证 PCB、电源、引脚、传感器方向或执行器映射。'
Write-Host ''
Write-Host "检查完成：$($script:FailureCount) 个失败，$($script:WarningCount) 个警告。本脚本只读取状态，没有修改源码。" -ForegroundColor Green

if ($script:FailureCount -gt 0) {
    exit 1
}
exit 0