# Clash on Windows (mihomo)

> **原文**: https://senzyo.net/2023-7/  
> **作者**: SenZyo  
> **说明**: 本文不使用 Clash Verge 等 GUI 客户端，而是通过任务计划程序或 Windows 服务和 Dashboard 网页来控制 Clash Meta Core (mihomo)。

---

## 目录

- [Core](#core)
- [配置文件](#配置文件)
- [Dashboard](#dashboard)
- [开机自启动](#开机自启动)
  - [方案一: 任务计划程序](#方案一-任务计划程序)
  - [方案二: Windows服务](#方案二-windows服务)
- [智能多宿主名称解析与防火墙](#智能多宿主名称解析与防火墙)
- [脚本](#脚本)
  - [当前模式重启](#当前模式重启)
  - [停止运行](#停止运行)
  - [切换模式重启](#切换模式重启)
  - [更新并备份Core](#更新并备份core)
- [关于脚本](#关于脚本)
  - [权限](#权限)
  - [不代理范围](#不代理范围)
- [FAQ](#faq)
  - [Core无法启动](#core无法启动)
  - [多个Core正在运行](#多个core正在运行)
  - [PowerShell脚本无法运行](#powershell脚本无法运行)
  - [UWP不走代理](#uwp不走代理)
- [附件](#附件)

---

## Core

参考 [FAQ](https://wiki.metacubex.one/faq/faq/) 下载[二进制文件](https://wiki.metacubex.one/startup/)，解压后将其重命名为 `mihomo.exe`。

---

## 配置文件

创建 mihomo 工作目录，比如 `C:\Users\<UserName>\Apps\mihomo`。放入配置文件 `config.yaml`。参考以下配置:

```yaml
# 官方参考配置 https://github.com/MetaCubeX/mihomo/blob/Alpha/docs/config.yaml
# 官方配置详解 https://wiki.metacubex.one/config/

mixed-port: 7890
allow-lan: false
bind-address: '*'

# 若非 always, SUB-RULE 不生效
find-process-mode: always
mode: rule

geox-url:
  geoip: "https://gh-proxy.org/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat"
  geosite: "https://gh-proxy.org/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
geo-auto-update: true
# 单位为小时
geo-update-interval: 24

log-level: error
ipv6: false

external-controller: 127.0.0.1:9090
secret: ""
external-controller-cors:
  allow-origins:
    - '*'
  allow-private-network: false

external-ui: ui
external-ui-url: 'https://gh-proxy.org/https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip'
# external-ui-url: 'https://gh-proxy.org/https://github.com/MetaCubeX/Yacd-meta/archive/refs/heads/gh-pages.zip'

global-client-fingerprint: chrome

profile:
  store-selected: true
  store-fake-ip: true

unified-delay: true
tcp-concurrent: true
geodata-mode: true
geodata-loader: standard

dns:
  enable: true
  prefer-h3: false
  use-hosts: true
  use-system-hosts: false
  respect-rules: false
  listen: 0.0.0.0:10053
  ipv6: false
  enhanced-mode: redir-host
  # 更多 DNS 参考: https://senzyo.net/2022-22/
  default-nameserver:
    - 'udp://223.5.5.5'
  nameserver-policy:
    # 为 proxy-provider 使用的域名指定 DNS 服务器, 不然无法下载订阅文件
    '+.gh-proxy.org,+.wd-turbo.com': ['https://dns.alidns.com/dns-query#DIRECT']
    'category-games@cn': ['https://dns.alidns.com/dns-query#DIRECT']
    'geosite:geolocation-!cn': ['tcp://8.8.8.8#🚀FinalOut']
    'geosite:cn': ['https://dns.alidns.com/dns-query#DIRECT']
  nameserver:
    - 'tcp://8.8.8.8#🚀FinalOut'
  proxy-server-nameserver:
    - 'https://dns.alidns.com/dns-query#DIRECT'

sniffer:
  enable: false
  force-dns-mapping: true
  parse-pure-ip: true
  override-destination: false

tun:
  enable: true
  stack: system
  auto-route: true
  auto-detect-interface: true
  dns-hijack:
    - 'udp://any:53'
    - 'tcp://any:53'
  strict_route: true
  endpoint-independent-nat: false
  exclude-package:
    - 'com.android.captiveportallogin'
    - 'org.localsend.localsend_app'

urltest: &urltest
  type: url-test
  disable-udp: false
  url: 'https://www.gstatic.com/generate_204'
  # 单位为秒, 仅影响 proxies 下的节点
  interval: 600
  # 单位为毫秒
  timeout: 2000
  # 单位为毫秒
  tolerance: 10
  lazy: false
  expected-status: 204
  use:
    - 'Provider1'

proxy-groups:
  - name: '🚀FinalOut'
    type: select
    disable-udp: false
    proxies:
      - '🌏日韩台新'
      - '📌单选节点'
      - '🇭🇰香港节点'
      - '🇯🇵日本节点'
      - '🇰🇷韩国节点'
      - '🇹🇼台湾节点'
      - '🇸🇬新加坡节点'
      - '🇺🇸美国节点'

  - name: '🌏日韩台新'
    filter: '🇯🇵|日本|JP|Japan|🇰🇷|韩国|KR|South Korea|🇹🇼|台湾|TW|Taiwan|🇸🇬|新加坡|SG|Singapore'
    <<: *urltest

  - name: '📌单选节点'
    type: select
    disable-udp: false
    exclude-filter: '剩余|流量|raffic|有效|时间|到期|xpire|地址|网址|官网|自动|最优|最快'
    use:
      - 'Provider1'

  - name: '📥Downloader'
    type: select
    disable-udp: false
    proxies:
      - '🚀FinalOut'
      - 'DIRECT'
      - '📌单选节点'
      - '🇭🇰香港节点'
      - '🇯🇵日本节点'
      - '🇰🇷韩国节点'
      - '🇹🇼台湾节点'
      - '🇸🇬新加坡节点'
      - '🇺🇸美国节点'

  - name: '🇭🇰香港节点'
    filter: '🇭🇰|香港|HK|Hong Kong'
    <<: *urltest

  - name: '🇯🇵日本节点'
    filter: '🇯🇵|日本|JP|Japan'
    <<: *urltest

  - name: '🇰🇷韩国节点'
    filter: '🇰🇷|韩国|KR|South Korea'
    <<: *urltest

  - name: '🇹🇼台湾节点'
    filter: '🇹🇼|台湾|TW|Taiwan'
    <<: *urltest

  - name: '🇸🇬新加坡节点'
    filter: '🇸🇬|新加坡|SG|Singapore'
    <<: *urltest

  - name: '🇺🇸美国节点'
    filter: '🇺🇸|美国|US|USA|United States'
    <<: *urltest

rules:
  # geoip.dat 类别: https://github.com/Loyalsoldier/geoip/tree/release/text
  # geosite.dat 类别:
  # https://github.com/v2fly/domain-list-community/tree/master/data
  # https://github.com/MetaCubeX/meta-rules-dat?tab=readme-ov-file#geositedatgeositedb-内容
  - GEOSITE,private,DIRECT
  - GEOIP,private,DIRECT,no-resolve
  - PROCESS-NAME,localsend,DIRECT
  - PROCESS-NAME,localsend_app.exe,DIRECT
  - DOMAIN-SUFFIX,gh-proxy.org,DIRECT
  - SUB-RULE,(RULE-SET,downloader),downloader
  - GEOSITE,category-games@cn,DIRECT
  - GEOSITE,geolocation-!cn,🚀FinalOut
  - GEOSITE,cn,DIRECT
  - GEOIP,cn,DIRECT,no-resolve
  - MATCH,🚀FinalOut

sub-rules:
  downloader:
    - GEOSITE,cn,DIRECT
    - GEOIP,cn,DIRECT,no-resolve
    - MATCH,📥Downloader

proxy-providers:
  Provider1:
    type: http
    url: "https://example.com"
    path: ./proxy_providers/Provider1.yaml
    # 单位为秒
    interval: 86400
    proxy: DIRECT
    health-check:
      enable: true
      url: 'https://www.gstatic.com/generate_204'
      # 单位为秒, 仅影响 proxy-group 中 use 下的节点
      interval: 600
      # 单位为毫秒
      timeout: 2000
      lazy: false
      expected-status: 204
    override:
      udp: true
      up: '30 Mbps'
      down: '100 Mbps'

rule-providers:
  downloader:
    type: http
    url: 'https://gh-proxy.org/https://raw.githubusercontent.com/senzyo/as-gist/refs/heads/master/Rule/Clash/downloader.yaml'
    path: ./rule-providers/downloader.yaml
    # 单位为秒
    interval: 604800
    behavior: classical
    format: yaml
```

---

## Dashboard

下载 [Yacd-meta](https://github.com/MetaCubeX/Yacd-meta/archive/refs/heads/gh-pages.zip) 或者 [MetaCubeXD](https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip)，解压后将文件夹重命名为 `ui`，移动到 mihomo 工作目录下: `C:\Users\<UserName>\Apps\mihomo\ui`。

后续一切工作正常后，可以打开 Dashboard (http://127.0.0.1:9090/ui) 查看相应信息并进行管理。

---

## 开机自启动

### 方案一: 任务计划程序

打开任务计划程序，点击右侧操作列表中的"创建任务":

**常规**  
名称填 `mihomo`。更改用户或组，输入 `system`，点击"检查名称"按钮，变为 `SYSTEM`，即使用 SYSTEM 账户。

**触发器**  
新建，开始任务选择`登录时`或`启动时`，按需选择延迟任务时间，确认勾选"已启用"。

**操作**  
新建，操作选择`启动程序`；程序或脚本填写 `mihomo.exe`；添加参数填写 `-d .\ -f config.yaml`；起始于填写 mihomo 工作目录，比如 `C:\Users\<UserName>\Apps\mihomo`。

**条件**  
全部取消勾选，包括灰显的。

**设置**  
1. 仅勾选"允许按需运行任务"。
2. 最下方的"如果此任务已经运行，以下规则适用"，确认选择"请勿启动新实例"。

### 方案二: Windows服务

利用 [winsw](https://github.com/winsw/winsw/releases) 安装 Windows 服务。

1. 将以下内容保存为 `mihomo service.xml`，和 `winsw.exe` 一起放入 mihomo 工作目录中:

```xml
<service>
    <startmode>Automatic</startmode>
    <id>mihomo service</id>
    <name>mihomo 服务</name>
    <description></description>
    <executable>mihomo.exe</executable>
    <arguments>-d .\ -f config.yaml</arguments>
    <log mode="none"></log>
</service>
```

> 注意，`<id>` 指 Name，`<name>` 指 DisplayName。更多 XML 设置参考[文档](https://github.com/winsw/winsw/blob/v3.0.0-alpha.11/docs/xml-config-file.md)。

2. 在 mihomo 工作目录中运行以下命令将 `mihomo service` 安装为 Windows 服务:

```shell
winsw.exe install "mihomo service.xml"
```

3. 运行服务，检查是否正常。

---

## 智能多宿主名称解析与防火墙

注意，在 Windows 中，如果在 TUN 配置中启用了严格路由:

1. 不必手动启用组策略中 `计算机配置 → 管理模板 → 网络 → DNS 客户端 → 禁用智能多宿主名称解析` 这一策略了，保持这一策略为`未配置/已禁用`即可。
2. 不必手动为 mihomo 配置 Windows 防火墙，mihomo 会自动配置的。
3. 不然，你会发现虽然测速延迟还可以，但实际速度很慢。
4. 由于 mihomo 和 sing-box 都使用 sing-tun，所以上述注意事项同样适用于 sing-box。

现在可以运行任务计划程序或 Windows 服务测试一下整个流程，应该一切正常。

现在可以打开 Dashboard (http://127.0.0.1:9090/ui) 查看相应信息并进行管理。

---

## 脚本

> 以下脚本适用于[方案一: 任务计划程序](#方案一-任务计划程序)。

### 当前模式重启

修改以下内容，写入到脚本 `C:\Users\<UserName>\Apps\mihomo\Restart.ps1`:

```powershell
$controller_api = "http://127.0.0.1:9090"
$api_secret = "AjIuQAZf795UQ16V3si6"
$task = "mihomo"
$process = "mihomo"
$proxy_port = 7890

Stop-ScheduledTask -TaskName $task
Stop-Process -Name $process -Force > $null 2>&1
Clear-DnsClientCache
Start-ScheduledTask -TaskName $task
Start-Sleep -Seconds 3

$state = Get-ScheduledTask -TaskName $task | Select-Object -ExpandProperty State
Write-Host "State of ${task}: ${state}"

if ($state -eq "Running") {
    $proxyEnabled = (Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings').ProxyEnable
    if ($proxyEnabled -eq 0) {
        Write-Host "System proxy disabled."
        Write-Host "Use tun mode."
        Invoke-RestMethod -Headers @{ "Authorization" = "Bearer $api_secret" } -ContentType "application/json" -Method PATCH -Body '{"tun": {"enable": true}}' -Uri "$controller_api/configs"
        Write-Host "TUN enabled."
    } else {
        Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer -Value "127.0.0.1:$proxy_port"
        Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Value 1
        Write-Host "System proxy enabled."
        Write-Host "Use system proxy mode."
        Invoke-RestMethod -Headers @{ "Authorization" = "Bearer $api_secret" } -ContentType "application/json" -Method PATCH -Body '{"tun": {"enable": false}}' -Uri "$controller_api/configs"
        Write-Host "TUN disabled."
    }
} else {
    Write-Host "Run ${task} failed."
}

Start-Sleep -Seconds 1
```

### 停止运行

修改以下内容，写入到脚本 `C:\Users\<UserName>\Apps\mihomo\Stop.ps1`:

```powershell
$task = "mihomo"
$process = "mihomo"

Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Value 0
Write-Host "System proxy disabled."
Stop-ScheduledTask -TaskName $task
Stop-Process -Name $process -Force > $null 2>&1
Write-Host "${process} stopped."
Clear-DnsClientCache
Start-Sleep -Seconds 1
```

### 切换模式重启

修改以下内容，写入到脚本 `C:\Users\<UserName>\Apps\mihomo\Switch.ps1`:

```powershell
$controller_api = "http://127.0.0.1:9090"
$api_secret = "AjIuQAZf795UQ16V3si6"
$task = "mihomo"
$process = "mihomo"
$proxy_port = 7890

$state = Get-ScheduledTask -TaskName $task | Select-Object -ExpandProperty State
Write-Host "State of ${task}: ${state}"

if ($state -ne "Running") {
    Stop-ScheduledTask -TaskName $task
    Stop-Process -Name $process -Force > $null 2>&1
    Clear-DnsClientCache
    Start-ScheduledTask -TaskName $task
    Start-Sleep -Seconds 3
    $state = Get-ScheduledTask -TaskName $task | Select-Object -ExpandProperty State
    Write-Host "State of ${task}: ${state}"
    if ($state -ne "Running") {
        Write-Host "Run ${task} failed."
        Start-Sleep -Seconds 2
        exit 1
    }
}

if ($state -eq "Running") {
    $proxyEnabled = (Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings').ProxyEnable
    if ($proxyEnabled -eq 0) {
        Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer -Value "127.0.0.1:$proxy_port"
        Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Value 1
        Write-Host "System proxy enabled."
        Write-Host "Use system proxy mode."
        Invoke-RestMethod -Headers @{ "Authorization" = "Bearer $api_secret" } -ContentType "application/json" -Method PATCH -Body '{"tun": {"enable": false}}' -Uri "$controller_api/configs"
        Write-Host "TUN disabled."
    } else {
        Write-Host "System proxy disabled."
        Write-Host "Use tun mode."
        Invoke-RestMethod -Headers @{ "Authorization" = "Bearer $api_secret" } -ContentType "application/json" -Method PATCH -Body '{"tun": {"enable": true}}' -Uri "$controller_api/configs"
        Write-Host "TUN enabled."
    }
}

Start-Sleep -Seconds 1
```

### 更新并备份Core

由于 mihomo 的 [Alpha](https://github.com/MetaCubeX/mihomo/releases/tag/Prerelease-Alpha) 版本更新很快，手动更新版本并备份到网盘也太麻烦了，干脆用 PowerShell 脚本自动下载核心到 OneDrive 的文件夹中，并覆盖 mihomo 工作目录中的旧版本可执行文件:

```powershell
$Releaseurl = "https://api.github.com/repos/MetaCubeX/mihomo/releases/tags/Prerelease-Alpha"
$Assets = Invoke-RestMethod -Uri $Releaseurl -Method Get
$AssetUrls = $Assets.assets | Where-Object {
    $_.name -like "mihomo-linux-amd64-alpha*gz" -or $_.name -like "mihomo-windows-amd64-alpha*zip"
} | Select-Object -ExpandProperty browser_download_url

# 不要使用中文路径
$ClashWorkPath = "$env:USERPROFILE\Apps\mihomo"
$DefaultDownloadPath = "$env:USERPROFILE\Downloads"
$LinuxBackupPath = "$env:OneDriveCommercial\Software\Linux\mihomo"
$WindowsBackupPath = "$env:OneDriveCommercial\Software\Windows\mihomo"
$task = "mihomo"
$process = "mihomo"

Get-ChildItem -Path $LinuxBackupPath, $WindowsBackupPath -Recurse | Remove-Item

foreach ($Url in $AssetUrls) {
    $FileName = [System.IO.Path]::GetFileName($Url)
    if ($FileName -like "*linux*") {
        $FilePath = "$LinuxBackupPath\$FileName"
    } elseif ($FileName -like "*windows*") {
        $FilePath = "$WindowsBackupPath\$FileName"
    } else {
        $FilePath = "$DefaultDownloadPath\$FileName"
    }
    Write-Host "Downloading $Url"
    Invoke-WebRequest -OutFile "$FilePath" -Uri "https://gh-proxy.org/$Url" -TimeoutSec 40
}

Stop-ScheduledTask -TaskName $task
Stop-Process -Name $process -Force > $null 2>&1
Clear-DnsClientCache
Expand-Archive -LiteralPath "$WindowsBackupPath\$FileName" -DestinationPath "$ClashWorkPath" -Force
Set-Location -Path $ClashWorkPath
Rename-Item -Path "mihomo-windows-amd64.exe" -NewName "mihomo.exe"
Start-ScheduledTask -TaskName $task
Start-Sleep -Seconds 3

$state = Get-ScheduledTask -TaskName $task | Select-Object -ExpandProperty State
Write-Host "State of ${task}: ${state}"
if ($state -eq "Running") {
    Write-Host "${task} successfully started."
} else {
    Write-Host "Run ${task} failed."
}

Start-Sleep -Seconds 1
```

---

## 关于脚本

mihomo 的外部控制 API 支持开关 TUN 模式。  
脚本的两个功能: 系统代理的开关是通过管理注册表实现的，TUN 模式的开关是通过 [PATCH](https://wiki.metacubex.one/api/#configs) 请求实现的。

### 权限

为 `.ps1` 脚本创建快捷方式，右击快捷方式，`属性 → 快捷方式 → 目标`，在脚本文件路径前添加 `powershell.exe -ExecutionPolicy Bypass -File`，注意 `-File` 和文件之间还有一个空格，比如:

```shell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\admin\Apps\mihomo\Stop.ps1"
```

点击"应用"。

此外，在`属性 → 快捷方式 → 高级`中勾选"用管理员身份运行"。

也可以在脚本开头加入以下自动提权代码:

```powershell
# 检查是否以管理员权限运行脚本
if (! ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # 如果没有管理员权限, 则重新以管理员权限运行脚本
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}
```

不要忘记设置脚本的权限，让普通用户仅限读取和执行。

这样一路设置下来，以后只需点击快捷方式即可。然后可以为快捷方式更换图标，参见[附件](#附件)。

### 不代理范围

脚本中可设置不代理的 IP 范围，即 `localhost`、`127.*`、IP 私有地址和本地 Intranet 范围:

```powershell
Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyOverride -Value "localhost;127.*;10.*;172.16.*;172.17.*;172.18.*;172.19.*;172.20.*;172.21.*;172.22.*;172.23.*;172.24.*;172.25.*;172.26.*;172.27.*;172.28.*;172.29.*;172.30.*;172.31.*;192.168.*;<local>"
```

IP 私有地址范围:
- A类地址范围: `10.0.0.0 ~ 10.255.255.255`
- B类地址范围: `172.16.0.0 ~ 172.31.255.255`
- C类地址范围: `192.168.0.0 ~ 192.168.255.255`

---

## FAQ

### Core无法启动

如果不能启动，请尝试更换版本，版本选择参考 [FAQ](https://wiki.metacubex.one/faq/faq/)。

### 多个Core正在运行

在 MetaCubeXD 中点击了"重启核心"和"更新核心"按钮，这时 mihomo 会重启，mihomo 的任务计划程序或者 Windows 服务转为就绪状态，如果这时再手动启动 mihomo 的任务计划程序或者 Windows 服务，就会有两个 mihomo 进程并存。

本文脚本中有重启 mihomo 的任务计划程序或者 Windows 服务的操作，所以 MetaCubeXD 搭配本文脚本使用不会出现此问题。

### PowerShell脚本无法运行

参考微软官方文档 [Set-ExecutionPolicy](https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.security/set-executionpolicy)，以管理员身份运行 PowerShell，执行以下命令:

```shell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### UWP不走代理

部分应用没有启用本地网络回环功能，特别是 UWP 应用，默认是关闭网络回环的。使用 [AppContainer Loopback Exemption Utility](https://www.telerik.com/fiddler/add-ons) 来开启这些应用的本地网络回环功能，使其流量经由系统代理。

---

## 附件

几个用于脚本快捷方式的自制图标:  
[f6ee563](https://github.com/senzyo/blog/commit/f6ee5636c4e821a571b420bd1f2f6e3628dca8fb)

---

> 原文链接: https://senzyo.net/2023-7/  
> 标签: Custom · Proxy · PowerShell · Windows  
> 许可证: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.zh-hans)
