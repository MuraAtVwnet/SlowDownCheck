﻿
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

	# ページファイル場所確認
	# /// ToDo

	# 状態チェック
	while($true){
		$DiskCounter = (Get-Counter "\PhysicalDisk(0 c:)\Avg. Disk sec/Transfer").CounterSamples.CookedValue
		$MemoryCounter = (Get-Counter "\Memory\Pages/sec").CounterSamples.CookedValue
		$Index = $DiskCounter * $MemoryCounter
		$IndexString = $Index.Tostring("0.0000")
		$OutputString = "(D)"+ $DiskCounter.Tostring("0.0000") + " * (M)" + $MemoryCounter.Tostring("#,0") + " = " + $IndexString
		# $OutputString = "(D)"+ $DiskCounter + " * (P)" + $MemoryCounter + " = " + $IndexString


		if( $MemoryCounter -ge 5 ){
			$OutputString += " : 過剰ページング"
		}
		if( $Index -ge 0.1 ){
			$OutputString += " / 著しいスローダウン"
		}

		Log "$OutputString"
		Sleep 5
	}
}

##########################################################################
# main
##########################################################################

PageingCheck

