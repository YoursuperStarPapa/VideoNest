# VideoNest 影视巢

一款基于 SwiftUI 的 iOS/iPadOS 视频聚合播放应用，参考影视仓设计。

## ✨ 功能特性

### 🎬 核心功能
- **多源聚合** - 支持 TVBox 标准 JSON API，可配置多个视频源
- **分类浏览** - 电影、电视剧、综艺、动漫、纪录片等全品类
- **全网搜索** - 跨源搜索，快速找到想看的内容
- **智能播放** - 自动解析播放地址，支持 m3u8/mp4/flv 等格式

### 📱 播放器
- 倍速播放 (0.5x - 3.0x)
- 字幕选择
- 音轨切换
- AirPlay 投屏
- 画中画 (PiP)
- 手势控制 (亮度/音量/进度)
- 游戏手柄支持

### 📲 iPad 适配
- NavigationSplitView 三栏布局
- 自适应网格 (LazyVGrid)
- 键盘快捷键支持
- Stage Manager 兼容

### 💾 数据管理
- 观看历史自动记录
- 收藏夹管理
- 播放进度云端同步
- 多仓接口一键导入

## 🏗 技术架构

```
VideoNest/
├── App/                    # 应用入口 & 状态管理
│   ├── VideoNestApp.swift  # @main 入口
│   └── AppState.swift      # 全局状态
├── Models/                 # 数据模型
│   └── VideoModels.swift   # TVBox API 模型
├── Networking/             # 网络层
│   └── TVBoxAPIClient.swift # API 客户端
├── ViewModels/             # MVVM ViewModel
│   ├── HomeViewModel.swift
│   ├── SearchViewModel.swift
│   └── DetailViewModel.swift
├── Views/                  # 视图层
│   ├── Home/               # 首页
│   ├── Detail/             # 详情页
│   ├── Player/             # 播放器
│   ├── Search/             # 搜索
│   ├── Settings/           # 设置
│   ├── Components/         # 通用组件
│   └── Shared/             # 共享视图
├── Services/               # 业务服务
│   ├── SourceManager.swift # 源管理
│   ├── DataStore.swift     # 数据持久化
│   └── PlayerManager.swift # 播放器管理
└── Extensions/             # 扩展
```

## 🔧 技术栈

| 技术 | 用途 |
|------|------|
| SwiftUI | 声明式 UI |
| MVVM | 架构模式 |
| AVKit / AVFoundation | 视频播放 |
| URLSession | 网络请求 |
| UserDefaults | 本地持久化 |
| Combine | 响应式编程 |
| async/await | 异步编程 |

## 📋 系统要求

- iOS 17.0+
- iPadOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone <repo-url>
cd VideoNest
```

### 2. 打开项目
```bash
open VideoNest.xcodeproj
```

### 3. 配置签名
在 Xcode 中选择你的开发者账号

### 4. 运行
选择 iPhone 或 iPad 模拟器，Cmd+R 运行

## 📖 使用说明

### 添加视频源
1. 打开「设置」→「视频源管理」
2. 点击「+」添加新源
3. 输入名称和 TVBox API 地址

### 导入多仓
1. 打开「设置」→「多仓管理」
2. 粘贴多仓地址
3. 点击「导入」

### 搜索影片
1. 切换到「搜索」标签
2. 输入影片名称
3. 点击搜索结果查看详情

## 🎯 TVBox API 兼容

本应用完全兼容 TVBox 标准 JSON API 格式：

```json
{
  "code": 1,
  "msg": "数据列表",
  "classes": [
    {"type_id": "1", "type_name": "电影"},
    {"type_id": "2", "type_name": "连续剧"}
  ],
  "list": [
    {
      "vod_id": "12345",
      "vod_name": "影片名称",
      "vod_pic": "https://...",
      "vod_play_from": "source1$$$source2",
      "vod_play_url": "第1集$url1#第2集$url2"
    }
  ]
}
```

## 📝 开发说明

### 添加新视频源
在 `SourceManager.swift` 中的 `addDefaultSources()` 方法添加

### 自定义 UI 主题
修改 `ViewExtensions.swift` 中的颜色定义

### 扩展播放器功能
在 `PlayerManager.swift` 中添加新的播放控制逻辑

## 📄 许可证

MIT License

## 🙏 致谢

- [TVBox](https://github.com/CatVod/CatVodOpen) - 开源视频聚合框架
- SwiftUI 社区 - 优秀的 UI 组件和设计灵感
