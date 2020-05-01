param ($sourcePath = '.', $outputPath = '.\output')

function EscapeString($string) {
    $string -replace '\\', '\\' -replace '\(', '\(' -replace '\)', '\)'
}

function Pad($depth) {
    "|" + "--" * $depth
}

function GetIncludeDirectives($fileContent) {
    $fileContent | Select-String -Pattern 'include\("([a-zA-Z/.-]+)"\)' -AllMatches
}

function GetFileWithIncludes($basePath, $relativeFilePath, $depth) {    
    $filePath = Join-Path $basePath $relativeFilePath
    
    Write-Host (Pad $depth)Processing $filePath

    $depth++

    $fileContent = Get-Content $filePath -Raw

    $includes = GetIncludeDirectives $fileContent

    foreach ($include in $includes.matches) {
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

if ($outputDirectoryExists -eq $False) {
    Write-Host Creating directory for output...

    New-Item -ItemType Directory -Force -Path $outputPath > $null

    Write-Host Created directory $outputPath
}

foreach ($fileName in $fileNames) {
    $outputFilePath = Join-Path $outputPath $fileName

    GetFileWithIncludes $sourcePath $fileName $depth | Out-File -FilePath $outputFilePath -Encoding ASCII

    Write-Host (Pad $depth)Saved $outputFilePath

    if ($fileName -ne $fileNames[-1]) {
        Write-Host (Pad 0)
    }
}

Write-Host Built ($fileNames.Count) scripts

# TODO: Add a parameter for building a single file
# TODO: Remove comments when processing files
# TODO: Remove duplicate new lines when processing files