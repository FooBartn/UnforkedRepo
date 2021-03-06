#requires -Modules Pester, Cisco.UcsManager

[CmdletBinding()]
Param(
    # Optionally fix all config drift that is discovered. Defaults to false (off)
    [switch]$Remediate = $false,

    # Optionally define a different config file to use.
    [string]$ConfigName
)

Process {
    # Tests
    Describe -Name 'Comprehensive: Chassis Discovery Policy' -Tag @('comprehensive','impact') -Fixture {
        BeforeAll {
            # Project Environment Variables 
            $ProjectDir = (Get-Item $PSScriptRoot).parent.parent.FullName
            $ConfigDir = $ProjectDir | Join-Path -ChildPath 'Configs'
            $ConfigFile = $ConfigDir | Join-Path -ChildPath "$ConfigName.ps1"
            $CredentialDir = $ProjectDir | Join-Path -ChildPath 'Credentials'
            
            # Ensure $UcsConfiguration is loaded into the session
            . $ConfigFile

            # Set variables from .connection
            $PuptrUser = $UcsConfiguration.Connection.Username
            $PuptrUserName = $PuptrUser.Split('\') | Select-Object -Last 1
            $PuptrUserPath = $CredentialDir | Join-Path -ChildPath "$PuptrUserName.txt"
            $UcsDomains = $UcsConfiguration.Connection.UcsDomain

            # Importing credentials
            $SecurePassword = Get-Content -Path $PuptrUserPath | ConvertTo-SecureString
            $Credential = [pscredential]::new($PuptrUser,$SecurePassword)

            # Connect to UCS 
            Connect-Ucs -Name $UcsDomains -Credential $Credential

            # Test Variables
            $MinimumChassisUplinks = $UcsConfiguration.Equipment.MinimumChassisUplinks
            $LinkAggregation = $UcsConfiguration.Equipment.LinkAggregation
        }

        # Run test case
        foreach ($UcsDomain in (Get-UcsStatus)) {
            # Get Chassis Info
            $ChassisDiscoveryPolicy = Get-UcsChassisDiscoveryPolicy -Ucs $UcsDomain.Name

            It -Name "$($UcsDomain.Name) has a minimum chassis uplink requirement of: $MinimumChassisUplinks" -Test {

                # Assert
                try {
                 $ChassisDiscoveryPolicy.Action | Should Be $MinimumChassisUplinks
                } catch {
                    if ($Remediate) {
                        Write-Warning -Message $_
                        Write-Warning -Message "Changing minimum uplink requirement to $MinimumChassisUplinks"
                        $ChassisDiscoveryPolicy | Set-UcsChassisDiscoveryPolicy -Action $MinimumChassisUplinks -Force
                    } else {
                        throw $_
                    }
                }
            }

            It -Name "$($UcsDomain.Name) has a link aggregation setting of: $LinkAggregation" -Test {

                # Assert
                try {
                 $ChassisDiscoveryPolicy.LinkAggregationPref | Should Be $LinkAggregation
                } catch {
                    if ($Remediate) {
                        Write-Warning -Message $_
                        Write-Warning -Message "Changing link aggregation preference to $LinkAggregation"
                        $ChassisDiscoveryPolicy | Set-UcsChassisDiscoveryPolicy -LinkAggregationPref $LinkAggregation -Force 
                    } else {
                        throw $_
                    }
                }
            }
        }

        # Disconnect from UCS
        Disconnect-Ucs
    }
}