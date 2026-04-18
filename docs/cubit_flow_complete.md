# Flutter BLoC / Cubit 调用全流程文档

> 以本项目 `NewsSongsCubit` 和 `ThemeCubit` 为例，梳理从 App 启动到 UI 渲染的完整链路。

---

## 一、整体架构分层

```
UI Layer (Widget)
    ↕ BlocProvider / BlocBuilder
Presentation Layer (Cubit / State)
    ↕ UseCase 调用
Domain Layer (UseCase / Repository 接口)
    ↕ 实现注入 (GetIt)
Data Layer (Repository Impl / Service)
    ↕ 网络 / 数据库
Infrastructure (CloudBase 云函数)
```

---

## 二、App 启动阶段 —— 依赖注入 & 全局 Cubit 注册

**文件：`main.dart` + `service_locator.dart`**

```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化 HydratedBloc 持久化存储（ThemeCubit 需要）
  HydratedBloc.storage = await HydratedStorage.build(...);

  // 2. 初始化 CloudBase（数据源）
  final cloudbaseApp = await CloudBase.init(...);

  // 3. 注册所有依赖到 GetIt 容器（sl）
  await initializeDependencies(cloudbaseApp: cloudbaseApp);

  runApp(const MyApp());
}
```

**`initializeDependencies` 注册链：**

```
GetIt (sl)
 ├── CloudBase（云函数客户端，单例）
 ├── AuthCloudbaseService → AuthRepository → Signin/SignupUseCase...
 └── SongCloudbaseService → SongRepository → GetNewsSongsUseCase
```

**全局 Cubit（在 Widget 树根部注册）：**

```dart
// MyApp.build
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => ThemeCubit()),  // 唯一全局 Cubit
  ],
  child: BlocBuilder<ThemeCubit, ThemeMode>(
    builder: (context, mode) => MaterialApp(themeMode: mode, ...),
  ),
)
```

`ThemeCubit` 继承自 `HydratedCubit`，状态会自动持久化到本地存储，App 重启后自动恢复主题。

---

## 三、局部 Cubit —— NewsSongsCubit 调用流程

### 3.1 触发点：Widget 挂载

```dart
// news_songs.dart
BlocProvider(
  create: (_) => NewsSongsCubit()..getNewsSongs(),  // 创建 Cubit 并立即发起请求
  child: BlocBuilder<NewsSongsCubit, NewsSongsState>(...)
)
```

`create: (_) => NewsSongsCubit()..getNewsSongs()` 这一行做了两件事：

1. 创建 `NewsSongsCubit` 实例，内部调用 `super(NewsSongsLoading())`，**立即发出初始 state**
2. 级联调用 `getNewsSongs()`，发起异步网络请求

---

### 3.2 Cubit 内部执行

```dart
// news_songs_cubit.dart
class NewsSongsCubit extends Cubit<NewsSongsState> {
  NewsSongsCubit() : super(NewsSongsLoading());  // ← 初始 state

  Future<void> getNewsSongs() async {
    // 调用 UseCase（通过 GetIt 获取实例）
    var returnedSongs = await sl<GetNewsSongsUseCase>().call();

    returnedSongs.fold(
      (error) => emit(NewsSongsLoadFailure()),          // 失败 → emit 失败状态
      (songs)  => emit(NewsSongsLoaded(songs: songs)),  // 成功 → emit 成功状态
    );
  }
}
```

---

### 3.3 完整调用链（数据流向）

```
NewsSongsCubit.getNewsSongs()
    ↓ await
GetNewsSongsUseCase.call()                // Domain 层 UseCase
    ↓ await
sl<SongRepository>().getNewsSongs()       // 通过 GetIt 获取仓库接口
    ↓ 实现类
SongRepositoryImpl.getNewsSongs()         // Data 层仓库实现
    ↓
sl<SongCloudbaseService>().getNewsSongs() // 数据源
    ↓ await
CloudBase.callFunction('getNewSongs')     // 调用腾讯云云函数
    ↓ 返回 JSON
SongModel.fromJson() → toEntity()         // 数据模型转换为领域实体
    ↓ Either<String, List<SongEntity>>
回到 Cubit → emit(NewsSongsLoaded) / emit(NewsSongsLoadFailure)
```

---

### 3.4 State 定义与流转

```dart
// news_songs_state.dart
abstract class NewsSongsState {}

class NewsSongsLoading extends NewsSongsState {}   // 初始态：转圈

class NewsSongsLoaded extends NewsSongsState {     // 成功态：渲染列表
  final List<SongEntity> songs;
  NewsSongsLoaded({required this.songs});
}

class NewsSongsLoadFailure extends NewsSongsState {} // 失败态：兜底容器
```

**State 流转时序：**

```
[App 渲染] → emit(NewsSongsLoading)    → UI: CircularProgressIndicator
[网络成功] → emit(NewsSongsLoaded)     → UI: ListView（歌曲列表）
[网络失败] → emit(NewsSongsLoadFailure)→ UI: Container(color: green)（兜底）
```

---

### 3.5 UI 响应层 —— BlocBuilder

```dart
BlocBuilder<NewsSongsCubit, NewsSongsState>(
  // 第一个泛型：告诉 BlocBuilder 监听哪个 Cubit
  // 第二个泛型：告诉 builder 回调里 state 参数的类型
  builder: (context, state) {
    // 每次 emit 新 state 都会触发此 builder 重新执行
    if (state is NewsSongsLoading) return CircularProgressIndicator();
    if (state is NewsSongsLoaded)  return _songs(state.songs);
    return Container(color: Colors.green); // NewsSongsLoadFailure 兜底
  },
)
```

**BlocBuilder 两个泛型的作用：**

| 泛型 | 作用 | 如果缺少 |
|------|------|---------|
| `NewsSongsCubit` | 从 Widget 树中查找并监听该 Cubit | 运行时找不到正确的 Cubit，报错 |
| `NewsSongsState` | 指定 `state` 参数的编译期类型 | `state` 退化为 `dynamic`，失去类型安全和 IDE 补全 |

---

## 四、两类 Cubit 对比

| | `ThemeCubit` | `NewsSongsCubit` |
|---|---|---|
| **作用域** | 全局（Widget 树根） | 局部（单页面生命周期） |
| **注册方式** | `MultiBlocProvider` in `MyApp` | `BlocProvider` in 页面 Widget |
| **状态类型** | `ThemeMode`（Flutter 枚举） | 自定义 `NewsSongsState` 子类 |
| **持久化** | ✅ `HydratedCubit`，自动序列化 | ❌ 内存态，页面销毁即清除 |
| **触发方式** | 手动调用 `updateTheme()` | 创建时自动触发 `getNewsSongs()` |
| **数据源** | 本地存储（hydrated_bloc） | 云函数（CloudBase） |

---

## 五、关键设计要点

### 5.1 GetIt 依赖注入（`sl<T>()`）

整个项目的依赖注入容器。所有 UseCase / Repository / Service 在 App 启动时一次性注册为单例，Cubit 中通过 `sl<T>()` 按需取用，**不直接持有具体实现**，保持 Domain 层对 Data 层的单向依赖。

### 5.2 Either 错误处理（dartz）

```dart
Either<Left（失败）, Right（成功）>

// 使用方式
result.fold(
  (error) => emit(NewsSongsLoadFailure()),   // Left 分支
  (songs)  => emit(NewsSongsLoaded(...)),    // Right 分支
);
```

替代 try-catch，强迫调用方显式处理成功和失败两种分支，不允许吞异常。

### 5.3 emit() 与生命周期

- `emit()` 是线程安全的，BLoC 内部保证 state 变更在同步上下文完成
- `BlocBuilder` 监听到新 state 后在**下一帧**重建 UI，不会阻塞当前帧
- `BlocProvider` 的作用域即 Cubit 的生命周期，Widget 销毁时自动调用 `Cubit.close()`

### 5.4 `..` 级联运算符（Cascade）

```dart
create: (_) => NewsSongsCubit()..getNewsSongs()
// 等价于：
create: (_) {
  final cubit = NewsSongsCubit();
  cubit.getNewsSongs();
  return cubit;
}
```

创建实例后立即触发初始化动作，是 Flutter 中常见的惯用写法。

---

## 六、调用流程总图

```
main()
  └─ initializeDependencies()  → 注册 GetIt 容器
  └─ runApp(MyApp)
       └─ MultiBlocProvider
            ├─ ThemeCubit（全局，持久化主题）
            └─ MaterialApp → SplashPage → ... → HomePage
                                                   └─ NewsSongs Widget
                                                        └─ BlocProvider
                                                             └─ NewsSongsCubit()..getNewsSongs()
                                                                  └─ GetNewsSongsUseCase
                                                                       └─ SongRepositoryImpl
                                                                            └─ SongCloudbaseServiceImpl
                                                                                 └─ CloudBase.callFunction()
                                                                                      ↓
                                                                             emit(NewsSongsLoaded)
                                                                                      ↓
                                                                          BlocBuilder 重建 ListView
```
