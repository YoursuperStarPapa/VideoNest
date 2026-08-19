# VideoNest 免费安装指南

## 📋 前提条件

| 项目 | 要求 |
|------|------|
| Mac | 一台 macOS 电脑（用于签名） |
| iPhone/iPad | iOS 17.0+ |
| Apple ID | 每台设备需要一个（免费即可） |
| USB 数据线 | 每台设备首次需要连接 Mac |

---

## 🚀 方案一：统一 Apple ID（推荐，最省事）

所有设备共用一个 Apple ID 签名，只需 Mac 操作一次。

### Mac 端操作（一次性）

1. **安装 AltServer**
   - 下载：https://altstore.io
   - 解压后拖入「应用程序」

2. **为第一台设备安装 AltStore**
   ```
   iPhone 连接 Mac
   → 菜单栏点击 AltServer 图标
   → Install AltStore → 选择设备
   → 输入 Apple ID 和密码
   → 等待安装完成
   ```

3. **打包 IPA**
   ```bash
   # Xcode 中：
   # 1. 选择 "Any iOS Device（arm64）"
   # 2. Product → Archive
   # 3. Distribute App → Development → 导出 IPA
   ```

### iPhone/iPad 端操作（每台设备）

1. **安装 AltStore**
   - 方法同上，每台设备都需要 AltServer 安装一次

2. **信任开发者**
   ```
   设置 → 通用 → VPN与设备管理
   → 找到对应 Apple ID → 信任
   ```

3. **导入 IPA 安装**
   ```
   打开 AltStore → 用同一个 Apple ID 登录
   → My Apps → + 号 → 选择 VideoNest.ipa
   → 等待安装完成
   ```

4. **每周续签**
   ```
   打开 AltStore → My Apps
   → 点击 VideoNest 旁的 "Refresh All"
   → 或连接 Mac 由 AltServer 自动续签
   ```

---

## 🔧 方案二：独立 Apple ID（各自签名）

每台设备用各自的 Apple ID 签名，互不影响。

### 步骤

对每台设备重复以下操作：

```bash
# 1. 设备连接 Mac
# 2. 打开 Xcode → Window → Devices and Simulators
# 3. 确认设备已连接

# 4. 修改签名 Team
#    Xcode → VideoNest target → Signing & Capabilities
#    → Team → 选择该设备对应的 Apple ID

# 5. Product → Archive → 导出 IPA

# 6. 用 AltStore 安装到该设备
```

### 多设备管理表

| 设备 | Apple ID | 签名状态 | 到期时间 |
|------|----------|---------|---------|
| 设备A | a@icloud.com | ✅ 已签名 | 7天后 |
| 设备B | b@icloud.com | ✅ 已签名 | 7天后 |
| 设备C | c@icloud.com | ⏳ 待签名 | - |

---

## ⏰ 续签机制

免费签名有效期 **7 天**，到期前需要续签：

### 自动续签（推荐）
```
AltStore → Settings → Refresh Apps Automatically → 开启
只要和 Mac 在同一 WiFi 下，AltServer 会自动续签
```

### 手动续签
```
AltStore → My Apps → Refresh All
或连接 Mac 后自动触发
```

### 续签提醒
在 iPhone 上创建快捷指令自动化：
```
快捷指令 → 自动化 → 创建个人自动化
→ 特定时间 → 每周五上午 10:00
→ 运行快捷指令 → "刷新 AltStore"
```

---

## ❓ 常见问题

### Q: 安装后提示"未受信任的开发者"
> 设置 → 通用 → VPN与设备管理 → 信任对应 Apple ID

### Q: 7 天后 App 打不开了
> 连接 Mac，打开 AltStore → Refresh All，重新签名

### Q: 免费账号能装几个 App？
> 同时最多 **3 个**（AltStore 自身占 1 个，实际可用 2 个）

### Q: AltStore 报错"Could not find Developer Disk Image"
> 更新 Xcode 到最新版本，或手动下载对应 iOS 版本的 DeveloperDiskImage

### Q: 设备重启后 App 消失
> 正常现象，重新通过 AltStore 安装即可

### Q: 续签时需要 Apple ID 密码吗
> AltStore 会通过 AltServer 处理，无需重复输入

---

## 📱 推荐工作流

```
Mac（签名机）
  │
  ├── AltServer 常驻运行
  │     └── 自动为同一 WiFi 下的设备续签
  │
  ├── 设备A ── WiFi ──┐
  ├── 设备B ── WiFi ──┤ 自动续签
  └── 设备C ── WiFi ──┘
```

**最佳实践：**
- Mac 保持 AltServer 常驻后台
- 所有设备连接同一 WiFi
- 开启 AltStore 自动刷新
- 每周检查一次签名状态

---

## 🔗 相关工具

| 工具 | 用途 | 下载 |
|------|------|------|
| AltStore | iOS 签名安装 | altstore.io |
| AltServer | Mac 端签名服务 | 随 AltStore 一起 |
| Sideloadly | 替代签名工具 | sideloadly.io |
| Xcode | 官方开发工具 | App Store |

---

*最后更新：2026-08-19*
