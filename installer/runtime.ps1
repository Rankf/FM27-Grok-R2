$ErrorActionPreference='Stop'
if(-not('FmGrokSignatureScanner'-as[type])){
 Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
public static class FmGrokSignatureScanner {
 static int[] Prefix(byte[] pattern) {
  int[] table = new int[pattern.Length];
  for (int i = 1, j = 0; i < pattern.Length; i++) {
   while (j > 0 && pattern[i] != pattern[j]) j = table[j - 1];
   if (pattern[i] == pattern[j]) j++;
   table[i] = j;
  }
  return table;
 }
 public static long[][] FindTwo(string path, byte[] first, byte[] second, long start, long length) {
  var one = new List<long>(); var two = new List<long>();
  int[] onePrefix = Prefix(first), twoPrefix = Prefix(second);
  int oneState = 0, twoState = 0; long position = start;
  using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read)) {
   stream.Position = start; byte[] buffer = new byte[4194304]; long remaining = length;
   while (remaining > 0) {
    int count = stream.Read(buffer, 0, (int)Math.Min(buffer.Length, remaining));
    if (count <= 0) break;
    for (int i = 0; i < count; i++, position++) {
     byte value = buffer[i];
     while (oneState > 0 && value != first[oneState]) oneState = onePrefix[oneState - 1];
     if (value == first[oneState] && ++oneState == first.Length) { one.Add(position - first.Length + 1); oneState = onePrefix[oneState - 1]; }
     while (twoState > 0 && value != second[twoState]) twoState = twoPrefix[twoState - 1];
     if (value == second[twoState] && ++twoState == second.Length) { two.Add(position - second.Length + 1); twoState = twoPrefix[twoState - 1]; }
    }
    remaining -= count;
   }
  }
  return new long[][] { one.ToArray(), two.ToArray() };
 }
}
'@
}
function Hash($p) { if(Test-Path -LiteralPath $p -PathType Leaf){$stream=[IO.File]::OpenRead($p);$algo=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($algo.ComputeHash($stream))).Replace('-','').ToLower()}finally{$stream.Dispose();$algo.Dispose()}} else {''} }
function Hex([string]$s){$b=New-Object byte[] ($s.Length/2);for($i=0;$i -lt $b.Length;$i++){$b[$i]=[Convert]::ToByte($s.Substring($i*2,2),16)};return ,$b}
function BytesEqual([byte[]]$a,[byte[]]$b){if($a.Length -ne $b.Length){return $false};for($i=0;$i -lt $a.Length;$i++){if($a[$i] -ne $b[$i]){return $false}};return $true}
function ReadBytes([string]$p,[long]$offset,[int]$length){$s=[IO.File]::OpenRead($p);try{[void]$s.Seek($offset,'Begin');$b=New-Object byte[] $length;if($s.Read($b,0,$length) -ne $length){throw 'DLL读取长度不足'};return ,$b}finally{$s.Dispose()}}
function PeSections([string]$p){$s=[IO.File]::OpenRead($p);try{$h=New-Object byte[] 8192;if($s.Read($h,0,$h.Length) -lt 1024){throw 'DLL文件过短'}}finally{$s.Dispose()};if($h[0]-ne 0x4d -or $h[1]-ne 0x5a){throw '不是PE文件'};$pe=[BitConverter]::ToInt32($h,0x3c);if([BitConverter]::ToUInt32($h,$pe)-ne 0x4550 -or [BitConverter]::ToUInt16($h,$pe+4)-ne 0x8664){throw '不是支持的64位PE文件'};$count=[BitConverter]::ToUInt16($h,$pe+6);$opt=[BitConverter]::ToUInt16($h,$pe+20);$base=$pe+24+$opt;$result=@();for($i=0;$i -lt $count;$i++){$o=$base+40*$i;$result+=,[pscustomobject]@{rva=[BitConverter]::ToUInt32($h,$o+12);size=[BitConverter]::ToUInt32($h,$o+16);raw=[BitConverter]::ToUInt32($h,$o+20);flags=[BitConverter]::ToUInt32($h,$o+36)}};return ,$result}
function TestHiddenGate([string]$p,[long]$raw){
 if($raw-lt 0){return $false}
 try{$b=ReadBytes $p $raw 19}catch{return $false}
 return $b[0]-eq0x80-and$b[1]-eq0x3d-and$b[6]-eq0-and$b[7]-eq0x74-and$b[8]-eq0x0a-and$b[9]-eq0x45-and$b[10]-eq0x31-and$b[11]-eq0xf6-and$b[12]-eq0x31-and$b[13]-eq0xdb-and$b[14]-eq0xe9
}
function JumpBytes([long]$raw,[long]$target){
 $distance=$target-($raw+6)
 if($distance-lt[int]::MinValue-or$distance-gt[int]::MaxValue){throw '跳转距离超出范围'}
 $result=New-Object byte[] 6;$result[0]=0x0f;$result[1]=0x84
 [Array]::Copy([BitConverter]::GetBytes([int]$distance),0,$result,2,4)
 return ,$result
}
function DllCandidates([string]$p,$locations,[int]$guardLength,[int]$skip){
 $result=@()
 foreach($guardRaw in $locations){
  $jumpRaw=[long]$guardRaw+$guardLength;$jump=ReadBytes $p $jumpRaw 6
  if($jump[0]-ne0x0f-or$jump[1]-ne0x84){continue}
  $target=$jumpRaw+6+[BitConverter]::ToInt32($jump,2)
  $gate=$null
  if(TestHiddenGate $p $target){$gate=$target}
  elseif(TestHiddenGate $p ($target-$skip)){$gate=$target-$skip}
  if($null-ne$gate){$result+=,[pscustomobject]@{jumpRaw=$jumpRaw;gate=[long]$gate;target=[long]$target}}
 }
 return ,$result
}
function DllState([string]$p,$profile){
 if(!(Test-Path -LiteralPath $p -PathType Leaf)){return [pscustomobject]@{state='missing';hash='';edits=@()}}
 $h=Hash $p
 try{
  $sections=PeSections $p;$skip=[int]$profile.skipBytes;$caGuard=Hex $profile.caGuard;$paGuard=Hex $profile.paGuard
  $caLocations=@();$paLocations=@()
  foreach($section in $sections){
   if(($section.flags-band 0x20000000)-and$section.size-ge$caGuard.Length){
    $matches=[FmGrokSignatureScanner]::FindTwo($p,$caGuard,$paGuard,[long]$section.raw,[long]$section.size)
    $caLocations+=@($matches[0]);$paLocations+=@($matches[1])
   }
  }
  $ca=@(DllCandidates $p ($caLocations|Sort-Object -Unique) $caGuard.Length $skip)
  $pa=@(DllCandidates $p ($paLocations|Sort-Object -Unique) $paGuard.Length $skip)
  $pairs=@();foreach($c in $ca){foreach($a in $pa){if($c.gate-eq$a.gate){$pairs+=,[pscustomobject]@{CA=$c;PA=$a;gate=$c.gate}}}}
  if($pairs.Count-ne 1){return [pscustomobject]@{state='unknown';hash=$h;edits=@();signaturePairs=$pairs.Count}}
  $pair=$pairs[0];$edits=@()
  foreach($name in @('CA','PA')){
   $item=$pair.$name;$original=JumpBytes $item.jumpRaw $item.gate;$patched=JumpBytes $item.jumpRaw ($item.gate+$skip)
   $on=$item.target-eq($item.gate+$skip)
   if(!$on-and$item.target-ne$item.gate){return [pscustomobject]@{state='unknown';hash=$h;edits=@();signaturePairs=1}}
   $edits+=,[pscustomobject]@{name=$name;raw=$item.jumpRaw;original=$original;patched=$patched;on=$on}
  }
  $caOn=[bool](($edits|Where-Object{$_.name-eq'CA'}|Select-Object -First 1).on)
  $paOn=[bool](($edits|Where-Object{$_.name-eq'PA'}|Select-Object -First 1).on)
  $state=if($caOn-and$paOn){'capa'}elseif($caOn){'ca'}elseif($paOn){'partial'}else{'original'}
  return [pscustomobject]@{state=$state;hash=$h;edits=$edits;signaturePairs=1;gateRaw=$pair.gate}
 }catch{return [pscustomobject]@{state='unknown';hash=$h;edits=@();signaturePairs=0}}
}
function ReplaceFileWithRetry([string]$source,[string]$destination,[string]$rollback){
 $last=$null
 for($attempt=1;$attempt-le10;$attempt++){
  try{[IO.File]::Replace($source,$destination,$rollback,$true);return}
  catch{$last=$_.Exception;if($attempt-lt10){Start-Sleep -Milliseconds 300}}
 }
 throw "无法替换 game_plugin.dll：文件持续被其他进程占用或拒绝访问。已自动重试 3 秒；请完全退出 FM27、Steam 更新和扫描该文件的程序后重试。系统信息：$($last.Message)"
}
function SetDllMode([string]$p,$profile,[ValidateSet('original','ca','capa')][string]$mode){
 $before=DllState $p $profile
 if($before.state -in @('missing','unknown')){throw '当前 DLL 显示结构不受支持'}
 if($before.state -eq $mode){return $before}
 $suffix=[Guid]::NewGuid().ToString()
 $temp=$p+'.'+$suffix+'.tmp'
 $rollback=$p+'.'+$suffix+'.rollback'
 try{
  Copy-Item -LiteralPath $p -Destination $temp
  $stream=[IO.File]::Open($temp,'Open','ReadWrite')
  try{
   foreach($edit in $before.edits){
    $enabled=($edit.name -eq 'CA' -and $mode -in @('ca','capa')) -or ($edit.name -eq 'PA' -and $mode -eq 'capa')
    $bytes=if($enabled){$edit.patched}else{$edit.original}
    [void]$stream.Seek($edit.raw,'Begin')
    $stream.Write($bytes,0,$bytes.Length)
   }
   $stream.Flush()
  }finally{$stream.Dispose()}
  if((DllState $temp $profile).state -ne $mode){throw '补丁副本校验失败'}
  if((Hash $p) -ne $before.hash){throw '运行时文件在检查后发生变化，请重新操作'}
  ReplaceFileWithRetry $temp $p $rollback
  $after=DllState $p $profile
  if($after.state -ne $mode){throw '替换后校验失败'}
  Remove-Item -LiteralPath $rollback
  return $after
 }catch{
  if(Test-Path -LiteralPath $rollback){Copy-Item -LiteralPath $rollback -Destination $p -Force}
  throw
 }finally{
  if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp}
 }
}
