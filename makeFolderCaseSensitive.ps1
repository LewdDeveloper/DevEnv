$targetVersion = 7
if ($PSVersionTable.PSVersion.major -ne $targetVersion) {
    Write-Host "pwsh version mismatched, .version = $targetVersion"
}

#yep, this one is a messy mf
function setCaseSensitiveInfo {
    Param
    (
        [Parameter(Mandatory = $true)] [string] $FolderPath,
        [Parameter(Mandatory = $true)] [int] $AwareCaseSensitive # 1 is enable, <> is disable
    )
    $_folderPath = $FolderPath
    $_awareCaseSensitive = $AwareCaseSensitive -ne 1 ? 'disable' : 'enable'  #pwsh 7
    $_condition = $AwareCaseSensitive -ne 1 ? '_disable_case_sensitive'  : '_enable_case_sensitive'
    $_folderName = Split-Path $_folderPath -Leaf
    $_newFolderName = $_folderName + $_condition
    $_newFolderPath = (Split-Path $_folderPath -Parent) + "\" + $_newFolderName

    # parent folder
    New-Item -Path $_newFolderPath -ItemType Directory -Force -Confirm 
    fsutil.exe file setCaseSensitiveInfo $_newFolderPath $_awareCaseSensitive

    # sub folder (haven't tested throughly yet!)
    Copy-Item "$_folderPath\*" $_newFolderPath -Filter {PSIsContainer} -Recurse -Force #-Confirm
    (Get-ChildItem -Path $_newFolderPath -Recurse -Directory).FullName | ForEach-Object {
        $setFlagResult = fsutil.exe file setCaseSensitiveInfo $_ enable
        if ($setFlagResult -replace '^.*(?=.{8}$)' -eq "enabled.") {
            Write-Host $setFlagResult
        }
        else {
            Write-Host "[FAIL] $_" -ForegroundColor Yellow
        }
    }

    Copy-Item "$_folderPath\*" $_newFolderPath -Recurse -Force # lazy mode
}

function queryCaseSensitiveInfo {
    Param
    (
        [Parameter(Mandatory = $true)] [string] $FolderPath
    )
    $_folderPath = $FolderPath

    if ($True -ne ( Test-Path -Path $_folderPath )) { return Write-Host "cannot find folder: $_folderPath" -ForegroundColor Red }
    
    (Get-ChildItem -Path $_folderPath -Recurse -Directory).FullName | ForEach-Object {
        $queryResult = fsutil.exe file queryCaseSensitiveInfo $_

        if ($queryResult -replace '^.*(?=.{8}$)' -eq "enabled.") {
            Write-Host $_ , "`u{279C}" -NoNewline
            Write-Host " enabled." -ForegroundColor DarkGreen
        }
        elseif ($queryResult -replace '^.*(?=.{9}$)' -eq "disabled.") {
            Write-Host $_ , "`u{279C}" -NoNewline
            Write-Host " disabled." -ForegroundColor DarkRed
        }
        else {
            Write-Host "exception caught : $queryResult"
        }
    }
}

# - . - . - . - #
#Write-Host "Enable or Disable Case Sensitive Attribute for Folders" -ForegroundColor Green
function ColorfulArray {
    Param
    (
        [Parameter(Mandatory = $true)] $I,
        [Parameter(Mandatory = $false)] $ColorIndex = 0
    )
    $_array_ = $I
    $_start_at = $ColorIndex
    for (($_index_ = 1); $_index_ -lt $_array_.count; $_index_++) {
        Write-Host (" | $_index_. ") -ForegroundColor ([Math]::Abs($_start_at - $_index_)) -NoNewline
        Write-Host ($_array_[$_index_])
    }
}

function invokeAction { }
#
$feature_ui = @($null, "queryCaseSensitiveInfo ", "setCaseSensitiveInfo")
ColorfulArray -I $feature_ui
$ref_feature_ui = Read-Host -Prompt "`u{1F527} Choose an option [1 `u{2794} 2]"

switch ($ref_feature_ui) {
    1 { $Function:invokeAction = $Function:queryCaseSensitiveInfo }
    2 { $Function:invokeAction = $Function:setCaseSensitiveInfo }
    default { throw "invalid token." }
}
#
$option_ui = @($null, (Get-Location), (Split-Path -Path (Get-Location)))
ColorfulArray($option_ui + "Pick a custom folder path") -ColorIndex 14
Write-Host "`u{26A0} Make sure no application is taking folder's handle"
$ref_option_ui = Read-Host -Prompt "`u{1F4C1} Choose an option [1 `u{2794} 2]"

if ($null -ne $option_ui[$ref_option_ui] ) {
    invokeAction -FolderPath $option_ui[$ref_option_ui]
}
else {
    invokeAction -FolderPath $ref_option_ui
}

#Write-Host ("See you again. * `u{1F44B} *") 