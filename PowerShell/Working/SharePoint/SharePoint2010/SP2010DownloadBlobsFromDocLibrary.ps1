## SharePoint Server 2010: PowerShell Script To Extract Blob Content To A File Location From A Document Library ##
## Overview: Script requires Site URL; List Library Name; and File Path location
## Resource: http://gallery.technet.microsoft.com/scriptcenter/1b0dfae9-19d9-4c2e-9c0a-4f1ff99e484b
## Testing Notes: Have had mixed results extracting certain file types like .PDF documents

param([string]$SiteUrl = $(Read-Host -Prompt "Please Enter Site Url")
, [string]$ListName = $(Read-Host -Prompt "Please enter name of document library")
, [string]$Output = $(Read-Host -Prompt "Enter Directory where you want to output the Blob content"))

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
function DownloadBlobsFromSPContentDB()
{
	if(([string]::IsNullOrEmpty($SiteUrl)) -and ([string]::IsNullOrEmpty($ListName)) -and ([string]::IsNullOrEmpty($Output)))
	{
		Write-Host "Required values missing..." ;
		break;
	}

	$Site = Get-SPSite -Identity $SiteUrl ;
	$Web = $Site.OpenWeb();

	$List = $Web.Lists[$ListName] ;

	if($List -eq $null)
	{
		Write-Host "Specified Document library does not exist"
		break;
	}

	#make a directory under the $output to store documents from a specific list
	$SiteIdGuid = $Site.ID.Guid
	Write-Host "Site Guid : $SiteIdGuid"
	$ListIdGuid = $List.ID.Guid
	Write-Host "List ID : $ListIdGuid"

	$ListFolder = "$Output\$SiteIdGuid-$ListName"

	if(Test-Path $ListFolder -Verbose)
	{
		Write-Host "Skipping directory creation under $OutPut"
	}
	else
	{
		
		New-Item -ItemType Directory $ListFolder -ErrorAction Stop
	}
	#*******************************************************************************
	# Build a query to retrieve the blobs directly from the content database
	#
	#********************************************************************************
	$ContentDatabase = $Site.ContentDatabase 
	$Conn ;
	$Cmd ;

	Try
	{
		[System.Data.SqlClient.SqlConnection]$Conn = New-Object -TypeName System.Data.SqlClient.SqlConnection 
		$Conn.ConnectionString = $ContentDatabase.DatabaseConnectionString
		$Conn.Open()
		
		[System.Data.SqlClient.SqlCommand]$Cmd = New-Object -TypeName System.Data.SqlClient.SqlCommand 
		$Cmd.Connection = $Conn 
		$Cmd.CommandType = [System.Data.CommandType]::Text
		$Cmd.CommandText = "Select ad.Id as Id, ad.SiteId as SiteId, ads.Content as Content, ad.LeafName as LeafName From AllDocs ad, AllDocStreams ads Where ad.Id = ads.Id  and ad.SiteId = ads.SiteId and ad.SiteId = @SiteIdGuid and ad.ListId = @ListIdGuid"
		#setup command parameters
		$Cmd.Parameters.Add("@SiteIdGuid", $SiteIdGuid)
		$Cmd.Parameters.Add("@ListIdGuid", $ListIdGuid)
		$Chunk = 1024
		[System.Data.IDataReader]$reader = $Cmd.ExecuteReader()
		while($reader.Read())
		{
			$StartIndex = 0
			#Write the blob to File System
			$ColumnIndex = $reader.GetOrdinal("Content");
			$FileNameColumnIndex = $reader.GetOrdinal("LeafName");
			if(($reader.IsDBNull($ColumnIndex)) -and ($reader.IsDBNull($FileNameColumnIndex)))
			{
				Write-Host "No Blobs to extract" 
			}
			else
			{
				$LeafName = $reader.GetValue($FileNameColumnIndex)
				$FileName = "$ListFolder\$LeafName"
				[System.IO.FileStream]$fs = New-Object System.IO.FileStream $FileName, ([System.IO.FileMode]::OpenOrCreate), ([System.IO.FileAccess]::Write)
				[System.IO.BinaryWriter]$bw = New-Object System.IO.BinaryWriter $fs;
			
				$size = $reader.GetBytes($ColumnIndex, 0, $null, 0,0)
				$buffer = New-Object byte[] $size			
				$reader.GetBytes($ColumnIndex, $StartIndex, $buffer, 0, $size)
				#write to file stream
				$bw.Write($buffer)
				$bw.Flush()
			}
		}
	}
	Finally
	{
		if($bw -ne $null)
		{
			$bw.Close()
		}
		if($fs -ne $null)
		{
			$fs.Dispose()
		}	
		$Conn.Dispose()
		$Site.Dispose();
		$Web.Dispose();
	}
}

DownLoadBlobsFromSPContentDB
