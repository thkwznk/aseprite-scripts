param ($sourcePath='.', $outputPath='.\output')

function EscapeString($string)
{
    $string -replace '\\', '\\' -replace '\(', '\(' -replace '\)', '\)'
}

function Pad($depth)
{
    "|" + "--" * $depth
}

$includeDirectivePattern = 'include\("([a-zA-Z/]+)"\)'

function GetFileWithIncludes($basePath, $relativeFilePath, $depth)
{    
    $filePath = Join-Path $basePath $relativeFilePath
    
    Write-Host (Pad $depth)Processing $filePath

    $fileContent = Get-Content $filePath -Raw

    $requires = $fileContent | Select-String -Pattern $includeDirectivePattern -AllMatches

    $depth++

    foreach ($require in $requires.matches)
    {
        Write-Host (Pad $depth)Linking $require.groups[1]

        $requirePath = $require.groups[1] -replace '/', '\'
        $requireRelativePath = "$basePath\$requirePath.lua"

        $dir = Split-Path -Path $requireRelativePath
        $file = Split-Path -Path $requireRelativePath -Leaf

        $dependencyContent = GetFileWithIncludes $dir $file (++$depth)
        $requireLine = EscapeString $require

        $fileContent = $fileContent -replace $requireLine, $dependencyContent
    }

    return $fileContent
}

Write-Host Building LUA scripts...

$fileNames = Get-ChildItem -Path $sourcePath -Filter *.lua -Name
$depth = 1

$outputDirectoryExists = Test-Path -Path $outputPath

if ($outputDirectoryExists -eq $False)
{
    Write-Host Creating directory for output...

    New-Item -ItemType Directory -Force -Path $outputPath > $null

    Write-Host Created directory $outputPath
}

foreach ($fileName in $fileNames)
{
    # Write-Host Processing $fileName

    $outputFilePath = Join-Path $outputPath $fileName

    GetFileWithIncludes $sourcePath $fileName $depth | Out-File -FilePath $outputFilePath -Encoding UTF8

    Write-Host (Pad $depth)Saved $outputFilePath
}

# TODO: Remove comments
# TODO: Remove duplicate new lines
# TODO: Recursive GetDependency function which can join relative path should solve the problem
