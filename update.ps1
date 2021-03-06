$queryPath = 'C:\GitHub\facilityui\MetasysFacilityService'
$envVars = @(
                @{
                    Name = 'SARROOT'
                    Path = '\\c7engs002\SARROOT'
                    Skip = $true
                }
                @{
                    Name = 'ca_dictionary_SARAsset'
                    Path = '\\c7engs002\SARROOT\sar\components\ca_dictionary_v1.0'
                    Build = '_int'
                }
                @{
                    Name = 'ca_mms_SARAsset'
                    Path = '\\c7engs002\SARROOT\sar\components\ca_mms_v3.0'
                    Build = '_int'
                }
                @{
                    Name = 'mmda_SARAsset'
                    Path = '\\c7engs002\SARROOT\sar\components\mmda_v6.3'
                    Build = '_int'
                }
                @{
                    Name = 'mmdb_SARAsset'
                    Path = '\\c7engs002\SARROOT\sar\components\mmdb_v2.0'
                    Build = '_int'
                }
                @{
                    Name = 'mmui_SARAsset'
                    Path = '\\c7engs002\SARROOT\sar\components\mmui_v1.0'
                    Build = '_int'
                }
            )
$configuration = 'Debug'

Write-Host 'Working...'
foreach ($envVar in $envVars)
{
    $psRoot = Get-Location

    # Set environment variables
    $envPath = $envVar.Path -replace '\\\\c7engs002\\SARROOT', $psRoot
    $envBuild = ''
    if (!$envVar.Skip)
    {
        $envPath = Join-Path $envPath '\latest'
        $envBuild = $envVar.Path.split('\\')[-1] + $envVar.Build

        # Move one directory forward
        $envVar.Path = Join-Path $envVar.Path $envBuild
    }
    [System.Environment]::SetEnvironmentVariable($envVar.Name, $envPath, [System.EnvironmentVariableTarget]::User)
    
    # Get the latest version
    $versionNumber = ''
    if (!$envVar.Skip)
    {
        $versionFile = Join-Path $envVar.Path '\current\version'
        $versionNumber = Get-Content $versionFile -TotalCount 1

        # Move one directory forward
        $envVar.Path = Join-Path $envVar.Path $versionNumber
    }

    # Scrape visual studio files to determine the needed files
    Get-ChildItem $queryPath -Recurse -Include '*.csproj' |
        Select-String -Pattern $envVar.Name |
        %{ $_.Line.Trim().Split() -replace '<HintPath>', '' -replace '</HintPath>', '' -replace "\$\($($envVar.Name)\)", '' -replace '<Content', '' -replace 'Include="', '' -replace '">', '' -replace '\$\(Configuration\)', "$configuration" -replace '\$\(ExternalConfiguration\)', "$configuration" } |
        Where-Object {$_ -ne ''} |
        Select -Unique |
        %{ Join-Path $envVar.Path $_ } |
        %{
            # Copy files from the build server to be local
            $newFile = $_ -replace '\\\\c7engs002\\SARROOT', $psRoot
            if (!$envVar.Skip)
            {
                $newFile = $newFile -replace "$envBuild\\", '' -replace $versionNumber, 'latest'
            }
            $newPath = Split-Path $newFile
            if (!(Test-Path $newPath))
            {
                md $newPath | Out-Null
            }
            Write-Host "Copying $_"
            Copy-Item $_ -Destination $newPath
        }
}
Write-Host 'Done'