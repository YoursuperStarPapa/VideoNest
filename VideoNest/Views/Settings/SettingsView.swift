import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddSource = false
    @State private var showImportURL = false
    @State private var importURL = ""
    @State private var showHistory = false
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("autoPlayNext") private var autoPlayNext = true
    @AppStorage("defaultPlaySource") private var defaultPlaySource = 0
    
    var body: some View {
        NavigationStack {
            List {
                // 视频源管理
                Section {
                    NavigationLink {
                        SourceManagementView()
                            .environmentObject(appState)
                    } label: {
                        Label("视频源管理", systemImage: "server.rack")
                    }
                    
                    Button {
                        showImportURL = true
                    } label: {
                        Label("导入接口", systemImage: "square.and.arrow.down")
                    }
                    
                    NavigationLink {
                        MultiRepoView()
                            .environmentObject(appState)
                    } label: {
                        Label("多仓管理", systemImage: "folder.fill")
                    }
                } header: {
                    Text("数据源")
                } footer: {
                    Text("管理 TVBox 接口地址，支持单仓和多仓格式")
                }
                
                // 播放设置
                Section("播放") {
                    Toggle(isOn: $autoPlayNext) {
                        Label("自动播放下一集", systemImage: "forward.end.fill")
                    }
                    
                    Picker("默认播放源", selection: $defaultPlaySource) {
                        Text("第一个").tag(0)
                        Text("上次使用").tag(1)
                    }
                }
                
                // 外观
                Section("外观") {
                    Picker("外观模式", selection: $appearance) {
                        Text("跟随系统").tag("system")
                        Text("浅色模式").tag("light")
                        Text("深色模式").tag("dark")
                    }
                    .onChange(of: appearance) { _, newValue in
                        switch newValue {
                        case "light": appState.colorScheme = .light
                        case "dark": appState.colorScheme = .dark
                        default: appState.colorScheme = nil
                        }
                    }
                }
                
                // 数据
                Section("数据") {
                    Button {
                        showHistory = true
                    } label: {
                        Label("观看历史", systemImage: "clock.arrow.circlepath")
                    }
                    
                    Button(role: .destructive) {
                        appState.dataStore.clearHistory()
                    } label: {
                        Label("清除观看记录", systemImage: "trash")
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("开源协议", systemImage: "doc.text")
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showImportURL) {
                importURLSheet
            }
            .sheet(isPresented: $showHistory) {
                HistoryView()
                    .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Import URL Sheet
    private var importURLSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 48))
                    .foregroundStyle(.accentColor)
                
                Text("导入 TVBox 接口")
                    .font(.headline)
                
                Text("支持 TVBox JSON 接口、多仓地址或纯文本链接列表")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField("输入接口地址...", text: $importURL)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                
                Button {
                    Task {
                        do {
                            let sources = try await appState.sourceManager.importFromURL(importURL)
                            for source in sources {
                                appState.sourceManager.addSource(source)
                            }
                            showImportURL = false
                            importURL = ""
                        } catch {
                            // Handle error
                        }
                    }
                } label: {
                    Text("导入")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)
                .disabled(importURL.trimmingCharacters(in: .whitespaces).isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("导入接口")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { showImportURL = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Source Management View
struct SourceManagementView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddSheet = false
    @State private var newSourceName = ""
    @State private var newSourceURL = ""
    @State private var newSourceGroup = "默认"
    
    var body: some View {
        List {
            ForEach(appState.sourceManager.sources) { source in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.name)
                            .font(.headline)
                        Text(source.apiURL)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if appState.sourceManager.activeSource?.id == source.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    
                    Toggle("", isOn: Binding(
                        get: { source.isActive },
                        set: { _ in appState.sourceManager.toggleSource(source) }
                    ))
                    .labelsHidden()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    appState.sourceManager.setActive(source)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        appState.sourceManager.removeSource(source)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
            .onMove { from, to in
                appState.sourceManager.sources.move(fromOffsets: from, toOffset: to)
            }
        }
        .navigationTitle("视频源管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addSourceSheet
        }
    }
    
    private var addSourceSheet: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $newSourceName)
                    TextField("API 地址", text: $newSourceURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("分组", text: $newSourceGroup)
                }
                
                Section {
                    Text("支持标准 TVBox JSON API 格式\n示例: https://example.com/api.php/provide/vod/")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("添加视频源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { showAddSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("添加") {
                        let source = VideoSource(
                            name: newSourceName,
                            apiURL: newSourceURL,
                            group: newSourceGroup
                        )
                        appState.sourceManager.addSource(source)
                        showAddSheet = false
                        newSourceName = ""
                        newSourceURL = ""
                        newSourceGroup = "默认"
                    }
                    .disabled(newSourceName.isEmpty || newSourceURL.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Multi Repo View
struct MultiRepoView: View {
    @EnvironmentObject var appState: AppState
    @State private var repoURL = ""
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.fill.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.accentColor)
            
            Text("多仓导入")
                .font(.title2.bold())
            
            Text("输入多仓地址，一键导入所有视频源")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField("多仓地址...", text: $repoURL)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal)
            
            if isLoading {
                ProgressView()
            }
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            Button {
                Task {
                    isLoading = true
                    self.error = nil
                    do {
                        let sources = try await appState.sourceManager.importFromURL(repoURL)
                        for source in sources {
                            appState.sourceManager.addSource(source)
                        }
                    } catch {
                        self.error = error.localizedDescription
                    }
                    isLoading = false
                }
            } label: {
                Text("导入")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
            .disabled(repoURL.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            
            Spacer()
        }
        .padding(.top, 40)
        .navigationTitle("多仓管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}
