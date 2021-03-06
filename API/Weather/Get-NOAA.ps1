Function Download-FiletoPath
{
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$Download,
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	
	Begin
	{
		
		$webclient = New-Object System.Net.WebClient
		
	}
	
	Process
	{
		
		$webclient.DownloadFile($Download, $Path)
		
	}
}

Function Download-SPCImages
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	begin
	{
		#Generate random seed to bypass possible caching problems
		$seed = Get-Random
		
		#Create folders
		New-Item -Path "$Path\SPC" -ItemType Directory | Out-Null
		New-Item -Path "$Path\SPC\Day01" -ItemType Directory | Out-Null
		New-Item -Path "$Path\SPC\Day02" -ItemType Directory | Out-Null
		New-Item -Path "$Path\SPC\Day03" -ItemType Directory | Out-Null
		
		
		#Gathering Data for the SPC outlook pages
		$spc1 = Invoke-WebRequest -Uri "http://www.spc.noaa.gov/products/outlook/day1otlk.html?$seed"
		$spc2 = Invoke-WebRequest -Uri "http://www.spc.noaa.gov/products/outlook/day2otlk.html?$seed"
		$spc3 = Invoke-WebRequest -Uri "http://www.spc.noaa.gov/products/outlook/day3otlk.html?$seed"
		
		#Getting the simplified print version of the outlook pages
		$SpcDay1URL = $spc1.Links | Where-Object -Property "innerHTML" -eq "Print Version" | Select-Object -ExpandProperty "href"
		$SpcDay2URL = $spc2.Links | Where-Object -Property "innerHTML" -eq "Print Version" | Select-Object -ExpandProperty "href"
		$SpcDay3URL = $spc3.Links | Where-Object -Property "innerHTML" -eq "Print Version" | Select-Object -ExpandProperty "href"
		
		#Loading the print version pages of the outlook pages into memory
		$spcDay1 = Invoke-WebRequest -Uri ("http://www.spc.noaa.gov/products/outlook/" + $spcDay1URL + "?$seed")
		$spcDay2 = Invoke-WebRequest -Uri ("http://www.spc.noaa.gov/products/outlook/" + $spcDay2URL + "?$seed")
		$spcDay3 = Invoke-WebRequest -Uri ("http://www.spc.noaa.gov/products/outlook/" + $spcDay3URL + "?$seed")
	}
	
	Process
	{
		#SPC Day 1
		$spcDay1Text = $spcDay1.ParsedHtml.body.getElementsByTagName("pre") | Select-Object -ExpandProperty "outerText"
		$spcDay1imgs = $spcDay1.Images | Select-Object -ExpandProperty "src" -Skip 2
		
		$spcDay1Text | Out-File -FilePath "$Path\SPC\Day01\Text.txt"
		
		$spcDay1full = @{ }
		foreach ($img in $spcDay1imgs)
		{
			$joinedLink = "http://www.spc.noaa.gov/products/outlook/$img" + "?$seed"
			$spcDay1full += @{ $img = $joinedLink }
			Download-FiletoPath -Download $joinedLink -Path "$Path\SPC\Day01\$img"
		}
		
		#SPC Day 2
		$spcDay2Text = $spcDay2.ParsedHtml.body.getElementsByTagName("pre") | Select-Object -ExpandProperty "outerText"
		$spcDay2imgs = $spcDay2.Images | Select-Object -ExpandProperty "src" -Skip 2
		
		$spcDay2Text | Out-File -FilePath "$Path\SPC\Day02\Text.txt"
		
		$spcDay2full = @{ }
		foreach ($img in $spcDay2imgs)
		{
			$joinedLink = "http://www.spc.noaa.gov/products/outlook/$img" + "?$seed"
			$spcDay2full += @{ $img = $joinedLink }
			Download-FiletoPath -Download $joinedLink -Path "$Path\SPC\Day02\$img"
		}
		
		#SPC Day 3
		$spcDay3Text = $spcDay3.ParsedHtml.body.getElementsByTagName("pre") | Select-Object -ExpandProperty "outerText"
		$spcDay3imgs = $spcDay3.Images | Select-Object -ExpandProperty "src" -Skip 2
		
		$spcDay3Text | Out-File -FilePath "$Path\SPC\Day03\Text.txt"
		
		$spcDay3full = @{ }
		foreach ($img in $spcDay3imgs)
		{
			$joinedLink = "http://www.spc.noaa.gov/products/outlook/$img" + "?$seed"
			$spcDay3full += @{ $img = $joinedLink }
			Download-FiletoPath -Download $joinedLink -Path "$Path\SPC\Day03\$img"
		}
	}
	
}

Function Download-WPCImages
{
	[cmdletbinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	begin
	{
		#Generate random seed to bypass possible caching problems
		$seed = Get-Random
		
		#Create folders
		Write-Verbose "Creating WPC folders."
		New-Item -Path "$Path\WPC" -ItemType Directory | Out-Null
		New-Item -Path "$Path\WPC\Short Range Forecasts" -ItemType Directory | Out-Null
		New-Item -Path "$Path\WPC\Medium Range Forecasts" -ItemType Directory | Out-Null
		
		#Gathering Data for the WPC Short Range Forecasts page.
		$wpc = Invoke-WebRequest -Uri "http://www.wpc.ncep.noaa.gov/basicwx/basicwx_ndfd.php?$seed"
		
		#Query the specific web elements we want.
		$wpcPage = $wpc.Images | Where-Object -Property "alt" -like "Forecast valid *"
		
	}
	
	process
	{
		#Short range forecasts download
		$i = 0
		foreach ($forecast in $wpcPage)
		{
			$i++
			$alt = $forecast | Select-Object -ExpandProperty "alt"
			$image = "http://www.wpc.ncep.noaa.gov" + ($forecast | Select-Object -ExpandProperty "src") + "?$seed"
			Write-Verbose "Downloading image from $image"
			Download-FiletoPath -Download $image -Path "$Path\WPC\Short Range Forecasts\$i - $alt.gif"
		}
		
		#Days 1-3 Forecast Charts
		$y = 1
		while ($y -le 3)
		{
			$image = "http://www.wpc.ncep.noaa.gov/noaa/noaad" + $y + ".gif?" + $seed
			Write-Verbose "Downloading image from $image"
			Download-FiletoPath -Download $image -Path "$Path\WPC\Day $y.gif"
			$y++
		}
		
		#Days 3-8 Medium Range Forecasts
		$z = 3
		while ($z -le 8)
		{
			$conusWPC = (Invoke-WebRequest -Uri "http://www.wpc.ncep.noaa.gov/medr/nav_conus_pmsl.php?fday=$z&fcolor=wbg&$seed").Images
			$image = "http://www.wpc.ncep.noaa.gov" + $conusWPC.src + "?$seed"
			$name = $conusWPC.alt
			Write-Verbose "Downloading image from $image"
			Download-FiletoPath -Download $image -Path "$Path\WPC\Medium Range Forecasts\$name.gif"
			$z++
		}
		
		#Current Surface Front Analysis
		$sfcCurFrontWeb = Invoke-WebRequest -Uri "http://www.wpc.ncep.noaa.gov/archives/web_pages/sfc/sfc_archive_maps.php?maptype=usfntsfc&$seed"
		
		$sfcCurFrontSplit = ($sfcCurFrontWeb.Images | Where-Object -Property "alt" -eq "Archived Surface Analysis" | Select-Object -ExpandProperty "src").split("/")
		$sfcCurFrontImage = "http://www.wpc.ncep.noaa.gov/archives/sfc/" + $sfcCurFrontSplit[3] + "/" + $sfcCurFrontSplit[4] + "?$seed"
		Write-Verbose "Downloading image from $sfcCurFrontImage"
		Download-FiletoPath -Download $sfcCurFrontImage -Path "$Path\WPC\Current Surface Front Analysis.gif"
		Download-FiletoPath -Download "http://www.wpc.ncep.noaa.gov/sfc/lrgnamsfcwbg.gif?$seed" -Path "$Path\WPC\Current Surface Front Analysis_HiRes.gif"
	}
}

Function Download-NWSDiscussion
{
	[cmdletbinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$Station,
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	begin
	{
		#Create folders
		Write-Verbose "Creating local station discussion folders."
		New-Item -Path "$Path\$Station" -ItemType Directory | Out-Null
		
		$afdNWS = Invoke-WebRequest -Uri "http://forecast.weather.gov/product.php?site=$Station&issuedby=$Station&product=AFD&format=txt&glossary=0"
		
	}
	Process
	{
		$afdNWS.ParsedHtml.body.getElementsByClassName("glossaryProduct") | Select-Object -ExpandProperty "innerHTML" | Out-File "$Path\$Station\AFD.txt"
	}
}
$curDateTime = Get-Date -Format "MM-dd-yyyy_HH-mm"
New-Item -Path "$env:USERPROFILE\NOAA\$curDateTime" -ItemType Directory

Download-SPCImages -Path "$env:USERPROFILE\NOAA\$curDateTime"
Download-WPCImages -Path "$env:USERPROFILE\NOAA\$curDateTime" -Verbose
Download-NWSDiscussion -Path "$env:USERPROFILE\NOAA\$curDateTime" -Station "Insert your local stationID"
