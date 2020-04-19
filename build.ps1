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

    foreach ($include in $requires.matches)
    {
        $relativePath = $include.groups[1] -replace '/', '\'
        $path = "$basePath\$relativePath.lua"

        Write-Host (Pad $depth)Linking $path

        $directory = Split-Path -Path $path
        $file = Split-Path -Path $path -Leaf

        $includeContent = GetFileWithIncludes $directory $file (++$depth)
        $requireLine = EscapeString $include

        $fileContent = $fileContent -replace $requireLine, $includeContent
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
    $outputFilePath = Join-Path $outputPath $fileName

    GetFileWithIncludes $sourcePath $fileName $depth | Out-File -FilePath $outputFilePath -Encoding ASCII

    Write-Host (Pad $depth)Saved $outputFilePath
}

# TODO: Remove comments
# TODO: Remove duplicate new lines
# TODO: Recursive GetDependency function which can join relative path should solve the problem
