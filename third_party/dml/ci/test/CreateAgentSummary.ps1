# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

<#
.SYNOPSIS
Collates agent info into a master summary.
#>
param
(
    [string]$TestArtifactsPath
)

$AllResults = @{}

$AgentPaths = Get-ChildItem $TestArtifactsPath -Directory
foreach ($AgentPath in $AgentPaths.FullName)
{
    $Result = @{}

    $DxDiagPath = "$AgentPath\dxdiag.xml"
    if (Test-Path $DxDiagPath)
    {
        $DxDiag = ([xml](Get-Content $DxDiagPath -Raw)).DxDiag

        $System = $DxDiag.SystemInformation
        $Adapter = @($DxDiag.DisplayDevices.DisplayDevice)[0]
    
        $Result.OperatingSystem = $System.OperatingSystem -replace '.*\((.*)\)$','$1'
        $Result.Processor = $System.Processor
        $Result.SystemManufacturer = $System.SystemManufacturer
        $Result.SystemModel = $System.SystemModel
        $Result.SystemDescription = "$($Result.SystemManufacturer) - $($Result.SystemModel)"
        $Result.DisplayAdapter = $Adapter.CardName
        $Result.DisplayDriver = $Adapter.DriverVersion
        $Result.DisplayDriverDate = $Adapter.DriverDate
        $Result.DisplayDriverModel = $Adapter.DriverModel
    
    }

    $EnvironmentVarsPath = "$AgentPath\environment_vars.json"
    if (Test-Path $EnvironmentVarsPath)
    {
        $AgentVars = Get-Content $EnvironmentVarsPath | ConvertFrom-Json
        if ($AgentVars.AutopilotSystemDescription)
        {
            $Result.SystemDescription = $AgentVars.AutopilotSystemDescription
        }
    }

    $AgentName = $AgentPath | Split-Path -Leaf
    $AllResults.$AgentName = $Result
}

ConvertTo-Json $AllResults -Depth 8 | Out-File "$TestArtifactsPath\agent_summary.json" -Encoding utf8