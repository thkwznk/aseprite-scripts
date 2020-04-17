
function EscapeString($string)
{
    $string -replace '\\', '\\' -replace '\(', '\(' -replace '\)', '\)'
}

Write-Host Building scripts

$includeDirectivePattern = '^include\("([a-zA-Z\\]+)"\)$'

$fileNames = Get-ChildItem -Path '.\*.lua' -Name

foreach ($fileName in $fileNames)
{
    Write-Host `tProcessing $fileName

    $fileContent = Get-Content $fileName

    $requires = $fileContent | Select-String -Pattern $includeDirectivePattern

    foreach ($require in $requires.matches)
    {
        Write-Host `t`tLinking $require.groups[1]

        $requirePath = $require.groups[1]
        $requireRelativePath = ".\$requirePath.lua"

        $dependencyContent = (Get-Content -Path $requireRelativePath -Encoding UTF8 -Raw)
        $requireLine = EscapeString($require)

        $fileContent = $fileContent -replace $requireLine, $dependencyContent
    }

    Set-Content -Path "..\$fileName" -Value $fileContent
}

# TODO: Remove duplicate new lines
# TODO: Recursive GetDependency function which can join relative path should solve the problem
# TODO: Add output path parameter