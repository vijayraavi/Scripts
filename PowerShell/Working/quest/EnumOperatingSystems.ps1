########################################################################
# Quest Script: Enum Operating Systems                                 #
# Searches Active Directory for computer accounts and collects         #
# information about installed operating systems                        #
#                                                                      #
# Requires ActiveRoles Management Shell for Active Directory installed #
#                                                                      #
# Resource: http://blog.riversen.dk/?p=62                              #
#                                                                      #
#                                                                      #
########################################################################
cls
Add-PSSnapin -name Quest.ActiveRoles.ADManagement

'Fetching computer accounts from Active Directory. This may take a while...'
$computers = Get-QADComputer | Sort-Object Name
'' + $computers.length + ' computer accounts fetched from Active Directory.'
'-----------------------------'

$stats = @{}

foreach( $computer in $computers )
{
    $OSName = $computer.OSName
    
    if( $OSName -eq $null )
    {
        $OSName = "Unknown OS"
    }
    
    $stats[$OSName]++

    #$computer.Name + "`t" + $computer.OSName + "`t" + $computer.OSVersion
}
$stats.GetEnumerator() | Sort-Object value
