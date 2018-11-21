##########################################################################
# メモリー不足状態確認
##########################################################################
Param( [switch]$RecordLog, [switch]$Help )

# ページング閾値
$GC_PageThreshold = 5

# ディスク IO 割合閾値
$GC_DiskThreshold = 0.1


# ログの出力先
$GC_LogPath = Convert-Path .
# ログファイル名
$GC_LogName = "SlowDownCheck"
##########################################################################
# ログ出力
##########################################################################
function Log(
			$LogString
			){

	$Now = Get-Date

	# Log 出力文字列に時刻を付加(YYYY/MM/DD HH:MM:SS.MMM $LogString)
	$Log = $Now.ToString("yyyy/MM/dd HH:mm:ss.fff") + " "
	$Log += $LogString

	# ログファイル名が設定されていなかったらデフォルトのログファイル名をつける
	if( $GC_LogName -eq $null ){
		$GC_LogName = "LOG"
	}

	# ログファイル名(XXXX_YYYY-MM-DD.log)
	$LogFile = $GC_LogName + "_" +$Now.ToString("yyyy-MM-dd") + ".log"

	# ログフォルダーがなかったら作成
	if( -not (Test-Path $GC_LogPath) ) {
		New-Item $GC_LogPath -Type Directory
	}

	# ログファイル名
	$LogFileName = Join-Path $GC_LogPath $LogFile

	# ログ出力
	Write-Output $Log | Out-File -FilePath $LogFileName -Encoding Default -append

	# echo
	[System.Console]::WriteLine($Log)
}


##########################################################################
# ページングチェック
##########################################################################
<#
	ディスク(ページファイル)速度 : \PhysicalDisk(0 c:)\Avg. Disk sec/Transfer
	ページング : \Memory\Pages/sec (この単体値が 5 を超える場合、メモリがボトルネックになっていると言える)
	ディスク速度 x ページング = ページ処理のディスク アクセス タイム割合
	この値が 0.1 を超える場合は、メモリー不足でパフォーマンスが著しく低下している状態の閾値
#>
function PageingCheck(){

	# ページファイル情報
	$PageFileInfo = Get-WmiObject -Class Win32_PageFileUsage
	$PageFilePath = $PageFileInfo.Name
	if( $PageFilePath -ne $null ){
		$Message = "[INFO] Page file path : $PageFilePath"
		if( $RecordLog ){
			Log $Message
		}
		else{
			# echo only
			[System.Console]::WriteLine($Message)
		}

		# ドライブレター
		$PageFileDrive = Split-Path $PageFilePath -Qualifier
		$PageFileDriveLetter = $PageFileDrive.Replace(":","")

		# ページファイルが存在するディスク番号
		$PageFilePartition = Get-Partition | ? { $_.DriveLetter -eq $PageFileDriveLetter }
		$PageFileDiskNumber = $PageFilePartition.DiskNumber

		$Message = "[INFO] Page file disk Number : $PageFileDiskNumber"
		if( $RecordLog ){
			Log $Message
		}
		else{
			# echo only
			[System.Console]::WriteLine($Message)
		}

		# ディスク カウンター
		$CounterName = "\PhysicalDisk($PageFileDiskNumber $PageFileDrive)\Avg. Disk sec/Transfer"

		$Message = "[INFO] Disk counter name : $CounterName"
		if( $RecordLog ){
			Log $Message
		}
		else{
			# echo only
			[System.Console]::WriteLine($Message)
		}

	}
	# ページファイル設定なし
	else{
		echo "ページファイルが設定されていません"
		exit
	}

	# 状態チェック
	while($true){
		$DiskCounter = (Get-Counter $CounterName).CounterSamples.CookedValue
		$MemoryCounter = (Get-Counter "\Memory\Pages/sec").CounterSamples.CookedValue
		$Index = $DiskCounter * $MemoryCounter
		$IndexString = $Index.Tostring("0.0000")
		$OutputString = "(D)"+ $DiskCounter.Tostring("0.0000") + " * (P)" + $MemoryCounter.Tostring("#,0") + " = " + $IndexString

		if( $MemoryCounter -ge $GC_PageThreshold ){
			$OutputString += " : 過剰ページング"
		}
		if( $Index -ge $GC_DiskThreshold ){
			$OutputString += " / スローダウン"
		}

		if( $RecordLog ){
			Log "$OutputString"
		}
		else{
			# echo only
			[System.Console]::WriteLine($OutputString)
		}
		Sleep 5
	}
}

##########################################################################
# help
##########################################################################
function Help(){
	$HelpFile = Join-Path $PSScriptRoot "SlowDownCheckReadMe.txt"
	Get-Content $HelpFile
	exit
}

##########################################################################
# main
##########################################################################

# ヘルプ表示
if( $Help ){
	Help
}

# ページング観察
PageingCheck


