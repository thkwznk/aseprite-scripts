
Write-Host Building scripts

$requirePattern = '^local ([a-zA-Z0-9]+) = require\("([a-zA-Z.]+)"\)$'

$fileNames = Get-ChildItem -Path '.\*.lua' -Name

foreach ($fileName in $fileNames)
{
    Write-Host `tProcessing $fileName

    $fileContent = Get-Content $fileName

    $requires = $fileContent | Select-String -Pattern $requirePattern

    foreach ($require in $requires.matches)
    {
        Write-Host `t`tLinking $require.groups[2]

        $requirePath = $require.groups[2] -replace '\.', '\'
        $requireRelativePath = ".\$requirePath.lua"

        $dependencyContent = (Get-Content -Path $requireRelativePath -Encoding UTF8 -Raw)
        $requireLine = $require -replace '\(', '\(' -replace '\)', '\)'

        $fileContent = $fileContent -replace $requireLine, $dependencyContent
    }

    Set-Content -Path "..\$fileName" -Value $fileContent
}

# TODO: Remove duplicate new lines
# TODO: Recursive GetDependency function which can join relative path should solve the problem
# TODO: Add output path parameter