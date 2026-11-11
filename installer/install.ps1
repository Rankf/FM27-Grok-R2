param([string]$GamePath='', [string]$UserPath='', [ValidateSet('','fixed','overlay','restore','check')][string]$Action='', [string]$Resolution='')
$ErrorActionPreference='Stop'
function Hash($p) { if(Test-Path -LiteralPath $p -PathType Leaf){$stream=[IO.File]::OpenRead($p);$algo=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($algo.ComputeHash($stream))).Replace('-','').ToLower()}finally{$stream.Dispose();$algo.Dispose()}} else {''} }
try {
 $manifest=Get-Content -LiteralPath "$PSScriptRoot\manifest.json" -Raw -Encoding UTF8 | ConvertFrom-Json
 Write-Host 'FM27 Grok - 基准 Build 26385295 R2.2 测试适配包（不含隐藏属性补丁）' -ForegroundColor Cyan
 if(!$GamePath){
  $candidates=@()
  $steam=(Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
  if($steam){
   $libraries=@($steam)
   $vdf=Join-Path $steam 'steamapps\libraryfolders.vdf'
   if(Test-Path -LiteralPath $vdf){
    foreach($match in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw),'"path"\s*"([^"]+)"')){$libraries+=$match.Groups[1].Value.Replace('\\','\')}
   }
   foreach($library in ($libraries | Select-Object -Unique)){$candidates+=Join-Path $library 'steamapps\common\Football Manager 27'}
  }
  $found=@($candidates | Where-Object {Test-Path -LiteralPath "$_\fm_Data\StreamingAssets\aa\StandaloneWindows64"} | Select-Object -Unique)
  if($found.Count -eq 1){$GamePath=$found[0]}
  elseif($found.Count -gt 1){Write-Host '发现多个游戏目录，请输入实际使用的目录。';$found | ForEach-Object {Write-Host $_}}
  if(!$GamePath){$GamePath=Read-Host '输入游戏目录（包含 fm_Data）'}
 }
 $GamePath=[IO.Path]::GetFullPath($GamePath.Trim('"'))
 $target=Join-Path $GamePath 'fm_Data\StreamingAssets\aa\StandaloneWindows64'
 if(!(Test-Path -LiteralPath $target)){throw '游戏目录不正确'}
 if(!$Action){
  Write-Host '1 固定侧边栏   2 浮动侧边栏   3 卸载并恢复正式版资源   4 只检查兼容性'
  switch(Read-Host '输入数字'){ '1'{$Action='fixed'} '2'{$Action='overlay'} '3'{$Action='restore'} '4'{$Action='check'} default {exit 0} }
 }
 # Read the appmanifest adjacent to this installation, rather than trusting the banner.
 $actualBuild=''; $buildReason='未找到匹配该安装目录的 Steam 清单'
 $steamapps=Split-Path (Split-Path $GamePath -Parent) -Parent
 $acf=Join-Path $steamapps 'appmanifest_4530370.acf'
 if(Test-Path -LiteralPath $acf){
  $acfText=Get-Content -LiteralPath $acf -Raw
  $appMatch=[regex]::Match($acfText,'"appid"\s*"([^"]+)"')
  $dirMatch=[regex]::Match($acfText,'"installdir"\s*"([^"]+)"')
  $buildMatch=[regex]::Match($acfText,'"buildid"\s*"(\d+)"')
  if($appMatch.Groups[1].Value -eq '4530370' -and $dirMatch.Success -and $buildMatch.Success){
   $manifestGame=[IO.Path]::GetFullPath((Join-Path (Join-Path $steamapps 'common') $dirMatch.Groups[1].Value))
   if($manifestGame.TrimEnd('\') -ieq $GamePath.TrimEnd('\')){$actualBuild=$buildMatch.Groups[1].Value;$buildReason='已从对应 Steam 清单读取'}
  }
 }
 if($actualBuild){Write-Host "实际 Steam Build: $actualBuild；安装包目标: $($manifest.build)"}
 else{Write-Host "实际 Steam Build: 未确认（$buildReason）"}
 $rows=@();$issues=@();$warnings=@();$legacyFound=$false
 if($actualBuild -and $actualBuild -ne $manifest.build){$warnings+='实际 Build 与制作基准不同；不单凭版本号拒绝安装，将检查全部相关资源。通过资源校验不代表新版游戏内兼容性已经实测。'}
 if(!$actualBuild){$warnings+='无法确认实际 Build；仅按资源校验判断安装，旧 Grok 升级仍需确认基准 Build。'}
 foreach($p in $manifest.files.PSObject.Properties){
  $n=$p.Name;$file=Join-Path $target $n;$h=Hash $file
  $state='未知文件';$allow=@($p.Value.accepted)+@($manifest.variants.fixed.$n,$manifest.variants.overlay.$n)
  if(!$h){$state='缺失';$issues+="缺少文件：$n"}
  elseif($h -eq $p.Value.base){$state='目标原版'}
  elseif($h -in $allow){$state='已识别适配包'}
  elseif($h -in @($p.Value.legacyGrokV2)){
   $state='已识别旧 Grok v2.0';$legacyFound=$true
   if($actualBuild -ne $manifest.build){$issues+="旧 Grok 升级需确认实际 Steam Build 为 $($manifest.build)：$n"}
  }else{$issues+="未识别的文件：$n；仅凭校验值不同无法判断来源。"}
  $bytes=$null;if(Test-Path -LiteralPath $file -PathType Leaf){$bytes=(Get-Item -LiteralPath $file).Length}
  $rows+=[pscustomobject]@{file=$n;state=$state;size=$bytes;sha256=$h;expectedOriginalSha256=$p.Value.base;originalInPackage="originals/$n"}
  if((Hash "$PSScriptRoot\originals\$n") -ne $p.Value.base){$issues+="安装包原始资源损坏：$n"}
 }
 $styleName='ui-styles_assets_default.bundle';$styleHash=Hash (Join-Path $target $styleName)
 $styleState='目标原版';if($styleHash -ne $manifest.styleHash){$styleState='未知或缺失';$issues+='样式资源不是目标正式版；不能与旧版原始样式混用。'}
 $rows+=[pscustomobject]@{file=$styleName;state=$styleState;sha256=$styleHash;expectedOriginalSha256=$manifest.styleHash}
 foreach($row in $rows){Write-Host "$($row.state)：$($row.file)";if($row.state -eq '未知文件' -or $row.state -eq '未知或缺失'){Write-Host "  实际 SHA-256: $($row.sha256)";Write-Host "  目标原版 SHA-256: $($row.expectedOriginalSha256)"}}
 # Restoring packaged originals requires either the baseline Build or evidence of
 # clean original resources observed during installation on THIS actual Build.
 $statePath=Join-Path $GamePath 'FM27_Grok_InstallState.json'
 $verifiedOriginals=($actualBuild -ne '' -and @($rows | Where-Object {$_.state -ne '目标原版'}).Count -eq 0)
 if(!$verifiedOriginals -and $actualBuild -and (Test-Path -LiteralPath $statePath)){
  try{
   $prior=Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
   $verifiedOriginals=($prior.actualBuild -eq $actualBuild -and $prior.verifiedOriginals -eq $true -and $prior.styleHash -eq $manifest.styleHash)
   foreach($p in $manifest.files.PSObject.Properties){if($prior.originalHashes.($p.Name) -ne $p.Value.base){$verifiedOriginals=$false}}
  }catch{$verifiedOriginals=$false}
 }
 $restoreAllowed=($issues.Count -eq 0 -and ($actualBuild -eq $manifest.build -or $verifiedOriginals))
 $restoreReason=''
 if(!$restoreAllowed){$restoreReason='不能确认本包原版适用于当前实际 Build；禁止跨版本写回。请使用 Steam 验证游戏文件完整性，或提供当前版本原版资源进行适配。'}
 if($issues.Count -eq 0 -and !$restoreAllowed){$warnings+='可以按已识别资源安装，但尚无当前 Build 的干净原版记录，菜单3暂不可用；需要恢复时请使用Steam验证。'}
 if($Action -eq 'restore' -and !$restoreAllowed -and $issues.Count -eq 0){$issues+=$restoreReason}
 foreach($warning in $warnings){Write-Host "警告：$warning" -ForegroundColor Yellow}
 $report=[ordered]@{installerRevision='R2.2';targetBuild=$manifest.build;detectedBuild=$actualBuild;buildDetection=$buildReason;files=$rows;issues=$issues;warnings=$warnings;action=$Action;canProceed=($issues.Count -eq 0);canRestore=$restoreAllowed;restoreReason=$restoreReason;verifiedOriginalsForCurrentBuild=$verifiedOriginals;note='Build变化先警告，资源未知仍停止；卸载恢复还要求实际Build或该Build的干净原版安装记录。'}
 try{
  $diag=Join-Path $PSScriptRoot 'Diagnostics';New-Item -ItemType Directory -Path $diag -Force | Out-Null
  $reportPath=Join-Path $diag ('compatibility_'+[DateTime]::Now.ToString('yyyyMMdd_HHmmss_fff')+'.json')
  $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding UTF8
  Write-Host "诊断报告（可用于反馈）：$reportPath"
 }catch{Write-Host '无法在安装包目录写入报告，请复制上面的检查结果。'}
 if($issues.Count -gt 0){$issues | ForEach-Object {Write-Host $_ -ForegroundColor Yellow};throw '检查未通过，游戏文件未修改。请提供诊断报告。不能直接覆盖未知资源或未经确认的跨版本原版文件。'}
 if($legacyFound){Write-Host '已识别旧 Grok 文件，实际 Build 匹配；安装时会先备份，再替换为本包适配资源。' -ForegroundColor Green}
 if($Action -eq 'check'){Write-Host '资源校验通过。本次未修改任何游戏文件。' -ForegroundColor Green;exit 0}
 if(!$UserPath){$UserPath=Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Sports Interactive\Football Manager 27'}
 if(!(Test-Path -LiteralPath $UserPath)){ $UserPath=Read-Host '输入用户目录（包含 games / skins）' }
 if(!(Test-Path -LiteralPath $UserPath)){throw '用户目录不存在'}
 $skin=Join-Path $UserPath 'skins\FM27_grok'
 if(Get-Process -Name fm -ErrorAction SilentlyContinue){throw '请先完全退出 FM27'}
 $sourceSkin=$null
 if($Action -ne 'restore'){
  $res=@('1920x1080','2560x1440','3840x2160','1366x768','1280x720','1440x900')
  if($Action -eq 'overlay'){$res+=@('1280x1024','1024x768')}
  if(!$Resolution){for($i=0;$i -lt $res.Count;$i++){Write-Host "$($i+1) $($res[$i])"};$choice=0;if(![int]::TryParse((Read-Host '选择分辨率编号'),[ref]$choice) -or $choice -lt 1 -or $choice -gt $res.Count){throw '编号无效'};$Resolution=$res[$choice-1]}
  if($Resolution -notin $res){throw '此侧边栏不支持所选分辨率'}
  $mapped=$Resolution;if($mapped -eq '1280x720'){$mapped='1366x768'};if($mapped -eq '1024x768'){$mapped='1280x1024'}
  $sourceSkin=Join-Path $PSScriptRoot "skins\FM27_grok_${Action}_$mapped"
  foreach($n in @('skin.json','grok.uss')){if(!(Test-Path -LiteralPath "$sourceSkin\$n")){throw "缺少皮肤文件 $n"}}
  foreach($p in $manifest.skinHashes.PSObject.Properties){if((Hash (Join-Path $PSScriptRoot $p.Name)) -ne $p.Value){throw "皮肤文件损坏：$($p.Name)"}}
  foreach($p in $manifest.variants.$Action.PSObject.Properties){if((Hash "$PSScriptRoot\bundles\$Action\$($p.Name)") -ne $p.Value){throw "安装包损坏：$($p.Name)"}}
 }
 $backup=Join-Path $GamePath ('FM27_Grok_26385295_Backups\'+[DateTime]::Now.ToString('yyyyMMdd_HHmmss_fff'))
 New-Item -ItemType Directory -Path "$backup\resources" -Force | Out-Null
 foreach($p in $manifest.files.PSObject.Properties){Copy-Item -LiteralPath (Join-Path $target $p.Name) -Destination "$backup\resources\$($p.Name)"}
 New-Item -ItemType Directory -Path "$backup\skin" -Force | Out-Null
 foreach($n in @('skin.json','grok.uss')){if(Test-Path -LiteralPath "$skin\$n"){Copy-Item -LiteralPath "$skin\$n" -Destination "$backup\skin\$n"}}
 $hadState=Test-Path -LiteralPath $statePath -PathType Leaf
 if($hadState){Copy-Item -LiteralPath $statePath -Destination "$backup\InstallState.json"}
 try {
  foreach($p in $manifest.files.PSObject.Properties){
   $n=$p.Name
   if($Action -eq 'restore'){$src="$PSScriptRoot\originals\$n";$want=$p.Value.base}else{$src="$PSScriptRoot\bundles\$Action\$n";$want=$manifest.variants.$Action.$n}
   Copy-Item -LiteralPath $src -Destination (Join-Path $target $n) -Force
   if((Hash (Join-Path $target $n)) -ne $want){throw "写入校验失败 $n"}
  }
  if($Action -eq 'restore'){
   foreach($n in @('skin.json','grok.uss')){if(Test-Path -LiteralPath "$skin\$n"){Remove-Item -LiteralPath "$skin\$n"}}
  }else{
   New-Item -ItemType Directory -Path $skin -Force | Out-Null
   foreach($n in @('skin.json','grok.uss')){Copy-Item -LiteralPath "$sourceSkin\$n" -Destination "$skin\$n" -Force;if((Hash "$skin\$n") -ne (Hash "$sourceSkin\$n")){throw '皮肤文件校验失败'}}
  }
  $originalHashes=[ordered]@{};foreach($p in $manifest.files.PSObject.Properties){$originalHashes[$p.Name]=$p.Value.base}
  [ordered]@{installerRevision='R2.2';actualBuild=$actualBuild;verifiedOriginals=$verifiedOriginals;styleHash=$manifest.styleHash;originalHashes=$originalHashes;lastAction=$Action} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath -Encoding UTF8
 } catch {
  foreach($p in $manifest.files.PSObject.Properties){Copy-Item -LiteralPath "$backup\resources\$($p.Name)" -Destination (Join-Path $target $p.Name) -Force}
  foreach($n in @('skin.json','grok.uss')){if(Test-Path -LiteralPath "$backup\skin\$n"){New-Item -ItemType Directory -Path $skin -Force | Out-Null;Copy-Item -LiteralPath "$backup\skin\$n" -Destination "$skin\$n" -Force}else{if(Test-Path -LiteralPath "$skin\$n"){Remove-Item -LiteralPath "$skin\$n"}}}
  if($hadState){Copy-Item -LiteralPath "$backup\InstallState.json" -Destination $statePath -Force}else{if(Test-Path -LiteralPath $statePath -PathType Leaf){Remove-Item -LiteralPath $statePath}}
  throw
 }
 Write-Host "完成。操作前备份：$backup" -ForegroundColor Green
 if($Action -eq 'restore'){Write-Host '重启游戏后选择默认皮肤。'}else{Write-Host '重启游戏，在设置中选择 FM27_grok。此包为测试适配版，请检查球员页、战术、比赛界面。'}
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
