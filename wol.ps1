#wol.ps1
#Tim Way
#http://way.vg/blog

#Handle Parameters: Start
param( [string]$attempts = 1,[string]$broadcasttosubnet = "255.255.255.255",[string]$fromfile = $null,[string]$mac = $null )
#Handle Parameters: End

#Function Code: Start
#Build-Packet
#Parameter $m: a mac address without any seperating characters. Example: ffaaffaaffaa
#Returns: an array of 102 byte elements. The first 6 bytes are always FF. The remaining elements are 16 copies of the mac address.
function Build-Packet-Payload($m)
{
	$m -match "^(..)-(..)-(..)-(..)-(..)-(..)$|^(..):(..):(..):(..):(..):(..)$|^(..)(..)(..)(..)(..)(..)$" | Out-Null
	switch ($matches.Keys)
	{
		{$_ -contains 1}{$m = [byte[]]($matches[1..6] | % {[int]"0x$_"})}
		{$_ -contains 7}{$m = [byte[]]($matches[7..12] | % {[int]"0x$_"})}
		{$_ -contains 13}{$m = [byte[]]($matches[13..18] | % {[int]"0x$_"})}
	}
	$p = [byte[]](,0xFF * 102)
	for ($z = 6; $z -lt 102; $z++) { $p[$z] = $m[($z%6)] }
	return $p
}

#Display-Packet-Payload
#Outputs the payload of a packet. This will most likely only be used for testing.
function Display-Packet-Payload($p)
{
	for ($z = 0; $z -lt 102; $z = $z +6) { for ($y = 0; $y -lt 6; $y++) { Write-Host -nonewline $p[$y+$z].ToString("X2") } Write-Host }
}

#Send-Packet
#Sends the WOL magic packets to a mac address based on input from the user
#Parameter $a: translates to the $attempts variable either input by the user or set to the default value of 1
#Parameter $b: translates to the $broadcasttosubnet variable either input by the user or set to the default value of "255.255.255.255"
#Parameter $p: the payload of the packet built by an earlier call to Build-Packet-Payload
#Parameter $u: the UdpClient .NET object to use to send the packet
function Send-Packet($a,$b,$p,$u)
{
	for ($z = 0; $z -lt $a; $z++) { $u.Send($p, $p.Length) | Out-Null }
}
#Function Code: End

#Declare Variables: Start
$macs = $null #an array of mac addresses that we will send WOL magic packets to
#Declare Variables: End

$udpclient = new-Object System.Net.Sockets.UdpClient
$udpclient.Connect($broadcasttosubnet,9)

if ($fromfile)
{
	if (Test-Path $fromfile)
	{
		$content = Get-Content $fromfile
		foreach ($z in $content)
		{
			if ($z -match "^(..)-(..)-(..)-(..)-(..)-(..)$|^(..):(..):(..):(..):(..):(..)$|^(..)(..)(..)(..)(..)(..)$")
			{
				$macs += ,$z
			}
		}
	}
	else
	{
		Write-Host "ERROR! -fromfile: file does not exist. no mac addresses to wake."
		Exit
	}
}
else
{
	$macs = ,$mac
}

foreach ($mac in $macs)
{
	$payload = Build-Packet-Payload $mac
	Send-Packet $attempts $broadcasttosubnet $payload $udpclient
}