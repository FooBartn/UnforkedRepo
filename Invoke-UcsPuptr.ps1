#requires -version 4 -Modules Cisco.UcsManager

<#

    .SYNOPSIS

    Provide an extremely light-weight approach to Cisco UCS configuration management

    .DESCRIPTION

    Utilize Pester and Cisco UCS PowerTool to provide a set if Operation Validation tests with the option
    to remediate if applicable.

    .PARAMETER TestPath

    Directory of the tests that you want to run.
    Default = '.\Ucs-Puptr'

    .PARAMETER FilePath

    Location of the configuration file you want to use.
    Default = 'Ucs-Puptr\Configs\Config.ps1

    .PARAMETER Remediate

    Defines whether or not to remediate applicable tests that have failed.
    Default = $false

    .PARAMETER TestName

    Informs Invoke-Pester to only run Describe blocks that match this name.

    .PARAMETER Tag

    Informs Invoke-Pester to only run Describe blocks tagged with the tags specified. Aliased 'Tags' for backwards
    compatibility.

    .PARAMETER ExcludeTag

    Informs Invoke-Pester to not run blocks tagged with the tags specified.
    Default: 'ucspuptr' : Keeps invoke-puptr from running pester on itself.

    .PARAMETER OutputFormat

    OutputFile format
    Options: LegacyNUnitXml, NUnitXml

    .PARAMETER OutputFile

    Location to dump pester results in format: $OutputFormat

    .PARAMETER Initialize

    Initial setup after you have edited your configuration files
    Default = $false

    .INPUTS

    None

    .OUTPUTS

    $OutputFile

    .NOTES

    Version:        1.0

    Author:         Joshua Barton (@foobartn)

    Creation Date:  10.19.2016

    Purpose/Change: Initial script development
    
    .EXAMPLE

    Initialize Ucs-Puptr before first run.

    .\Invoke-UcsPuptr -Initialize

    .EXAMPLE

    Run all config and operational validation tests. (Default)

    .\Invoke-UcsPuptr

    .EXAMPLE

    Run all config and operational validation tests and remediate.

    .\Invoke-UcsPuptr -Remediate

    .EXAMPLE

    Run all tests with Configuration in the name.

    .\Invoke-UcsPuptr -TestName '*Configuration*'

    .EXAMPLE

    Run and exclude specifically tagged tests.

    .\Invoke-UcsPuptr -Tag 'ucsm' -ExcludeTag 'server'

#>



#---------------------------------------------------------[Script Parameters]------------------------------------------------------

param (

  [Parameter(Mandatory=$false)]
  [string]
  $TestPath = "$PSScriptRoot\Tests",

  [Parameter(Mandatory=$false)]
  [string]
  $FilePath = "$PSScriptRoot\Configs\Config.ps1",

  [Parameter(Mandatory=$false)]
  [switch]
  $Remediate = $false,

  [Parameter(Mandatory=$false)]
  [string[]]
  $TestName = $null,

  [Parameter(Mandatory=$false)]
  [string[]]
  $Tag = $null,

  [Parameter(Mandatory=$false)]
  [string[]]
  $ExcludeTag = $null,

  [Parameter(Mandatory=$false)]
  [ValidateSet('NUnitXml,LegacyNUnitXml')]
  [string]
  $OutputFormat = $null,

  [Parameter(Mandatory=$false)]
  [string]
  $OutputFile = $null,

  [Parameter(Mandatory=$false)]
  [switch]
  $Initialize = $false

)

#-------------------------------------------------------[Parameter Setup]------------------------------------------------------

# Parameters to pass to individual tests
$TestParam = @{
    Remediate = $Remediate
    Config = $FilePath
}

# Hash of Pester parameters that could be splatted
$PesterBaseParam = @{
    TestName = $null
    Tag = $null
    ExcludeTag = $null
    OutputFormat = $null
    OutputFile = $null
}

# Initiliaze empty hash for splattable Pester parameters
$PesterParam = @{}

#----------------------------------------------------[Initialize Configuration]-------------------------------------------------

if ($Initialize) {
    Invoke-Pester "$PSScriptRoot\Configs"
} else {

#---------------------------------------------------------[Execute Tests]------------------------------------------------------

    # For every parameter that isn't $null, add it to $PesterParam
    foreach ($BaseParam in $PesterBaseParam.Keys) {
        $BaseParamValue = Get-Variable -Name $BaseParam -ValueOnly -ErrorAction SilentlyContinue
        if ($BaseParamValue) {
            $PesterParam.Add($BaseParam,$BaseParamValue)
        }
    }

    # Run Pester with specified variables and parameters
    Invoke-Pester -Script @{Path = $TestPath; Parameters = $TestParam} @PesterParam

}