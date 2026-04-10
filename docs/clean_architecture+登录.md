# Clean Architecture 架构设计文档

> 本文档先建立「学术命名 ↔ 实践命名」的对照关系，再逐层讲清职责边界（含绝对禁忌），最后结合本项目 Signup 功能与多接口加载场景做实战验证。

---

## 目录

1. [核心思想：一句话概括](#1-核心思想一句话概括)
2. [命名对照：学术层 vs 实践层](#2-命名对照学术层-vs-实践层)
3. [各层职责详解（含绝对禁忌）](#3-各层职责详解含绝对禁忌)
4. [实战场景：两个完整示例](#4-实战场景两个完整示例)
5. [本项目 Signup 功能对照](#5-本项目-signup-功能对照)
6. [层间隔离的真实程度](#6-层间隔离的真实程度)
7. [终极总结](#7-终极总结)

---

## 1. 核心思想：一句话概括

> **业务规则不应依赖于任何实现细节（数据库、UI 框架、网络库）。**

当你切换 Firebase → REST API、Flutter → React Native、AFNetworking → Dio 时，**业务逻辑代码一行都不应该改动**。实现这个目标的手段，就是分层 + 依赖方向控制。

**依赖的唯一铁律：** 外层可以知道内层，内层绝对不能知道外层。

```
外层 ──依赖──▶ 内层    ✅
内层 ──依赖──▶ 外层    ❌ 违反架构
```

---

## 2. 命名对照：学术层 vs 实践层

整洁架构原书（Uncle Bob）定义了 4 个抽象层，行业落地时演化出了更具体的命名。**两套命名说的是同一件事，只是粒度不同。**

```
┌──────────────────────────────────────────────────────────────────┐
│          Uncle Bob 学术命名            行业实践命名               │
│                                                                  │
│  ┌─────────────────────────┐    ┌──────────────────────────┐    │
│  │   Frameworks & Drivers  │    │       UI 层              │    │
│  │  （框架与驱动层，最外层）   │    │  Page / ViewController   │    │
│  └───────────┬─────────────┘    └──────────┬───────────────┘    │
│              │                             │                     │
│  ┌───────────▼─────────────┐    ┌──────────▼───────────────┐    │
│  │  Interface Adapters     │    │    Repository 层          │    │
│  │  （接口适配层）            │    │  + DataSource 层          │    │
│  └───────────┬─────────────┘    └──────────┬───────────────┘    │
│              │                             │                     │
│  ┌───────────▼─────────────┐    ┌──────────▼───────────────┐    │
│  │      Use Cases          │    │     UseCase 层            │    │
│  │  （用例层，业务逻辑）      │    │   业务规则 / 流程编排       │    │
│  └───────────┬─────────────┘    └──────────┬───────────────┘    │
│              │                             │                     │
│  ┌───────────▼─────────────┐    ┌──────────▼───────────────┐    │
│  │       Entities          │    │     Entity / Model 层     │    │
│  │  （实体层，最内层）        │    │  纯业务数据对象（无框架依赖）  │    │
│  └─────────────────────────┘    └──────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

### 映射关系说明

| Uncle Bob 命名 | 行业实践命名 | Flutter 对应 | iOS 对应 |
|---|---|---|---|
| Entities | Entity / Model | `UserEntity` 等纯 Dart 类 | 纯 Objective-C / Swift 数据类 |
| Use Cases | UseCase | `SignupUseCase` | `LoginUseCase` |
| Interface Adapters | Repository + DataSource | `AuthRepositoryImpl` + `AuthFirebaseServiceImpl` | `AuthRepository` + `AuthRemoteDataSource` |
| Frameworks & Drivers | UI + 外部 SDK | `SignupPage` + Firebase SDK | `LoginViewController` + AFNetworking |

> **注意：** 原书并没有定义 Repository 和 DataSource 这两个词，这是行业约定俗成的拆分。Repository 承担"数据编排"（Interface Adapters 的主要职责），DataSource 承担"数据执行"（Frameworks & Drivers 的数据端部分）。

---

## 3. 各层职责详解（含绝对禁忌）

按"从外到内"顺序，每层明确：核心定位、具体职责、绝对禁忌。

---

### 3.1 UI 层（最外层）

**对应学术层：** Frameworks & Drivers 的 UI 端

**核心定位：** 最薄、最干净的一层，只负责"界面交互与展示"，是用户和系统之间的窗口。

**具体职责（只做 4 件事）：**
- 响应用户操作：按钮点击、输入框、下拉刷新
- 调用 UseCase：仅触发执行，不关心 UseCase 内部逻辑
- 更新界面：展示 UseCase 返回的数据或错误提示
- 页面跳转：登录成功跳主页、退出登录跳登录页

**绝对禁忌：**
- ❌ 不做参数校验（"账号不能为空"这种判断属于业务规则，交给 UseCase）
- ❌ 不做业务判断（"用户是否已登录"是业务逻辑，不在 UI 层处理）
- ❌ 不发网络请求（UI 层不知道网络的存在）
- ❌ 不直接操作数据库
- ❌ 不 import Repository 或 DataSource 的具体实现类

---

### 3.2 UseCase 层（业务逻辑层）

**对应学术层：** Use Cases

**核心定位：** 业务大脑，是整洁架构的核心价值所在。代表「系统能做什么」，每个 UseCase 对应一个用户意图（User Story）。

**具体职责：**
- 参数校验：账号非空、密码长度、手机号格式
- 业务规则判断：用户是否登录、权限是否足够、余额是否充足
- 流程编排：调用 Repository 获取数据，对数据做业务层面的处理
- 业务后置处理：登录成功后保存 Token、注册成功后发送欢迎通知
- 抛出业务异常：账号为空、未登录、余额不足等

**绝对禁忌：**
- ❌ 不发网络请求（不知道网络的存在）
- ❌ 不直接操作数据库
- ❌ 不做 JSON → Model 的数据转换（这是 Repository/DataSource 的职责）
- ❌ 不处理 UI 相关逻辑（不调用 Navigator、不显示 Toast、不知道 Flutter/UIKit 的存在）
- ❌ 不直接调用 DataSource（只通过 Repository 接口获取数据）

---

### 3.3 Repository 层（数据仓库层）

**对应学术层：** Interface Adapters（主体部分）

**核心定位：** 数据调度员，是 UseCase 和 DataSource 之间的桥梁。负责"数据编排、数据源选择、数据格式转换"，不涉及任何业务逻辑。

**具体职责：**
- 调用 DataSource：获取原始数据（网络、数据库、缓存）
- 数据转换：将原始数据（JSON/字典）转换为 UseCase 需要的 Entity/Model
- 数据编排：组合多个 DataSource 请求（如首页并发加载 4 个接口）
- 缓存策略：判断读缓存还是读网络，网络数据回来后同步更新缓存
- 数据源切换：开发环境用 Mock DataSource，线上用 Remote DataSource

**绝对禁忌：**
- ❌ 不做业务规则判断（"过滤已读公告"是业务规则，属于 UseCase）
- ❌ 不做参数校验
- ❌ 不直接发网络请求（把具体的 HTTP 调用交给 DataSource）
- ❌ 不处理 UI 相关逻辑

**Repository vs DataSource 本质区别：**

> DataSource 是"零件"（每个方法只做一个最小数据操作）  
> Repository 是"组装工人"（决定用哪些零件、怎么组装、结果怎么转换）

---

### 3.4 DataSource 层（数据源层）

**对应学术层：** Frameworks & Drivers 的数据端

**核心定位：** 真正的"数据执行者"，只负责与外部系统打交道（Firebase、REST API、SQLite、SharedPreferences）。

**具体职责：**
- 网络请求：用 Dio、AFNetworking、firebase_auth 等 SDK 发请求，返回原始数据
- 本地操作：读写数据库、SharedPreferences、本地文件
- 最小原子操作：每个方法只做一件事，不组合、不判断

**绝对禁忌：**
- ❌ 不做业务逻辑判断
- ❌ 不做数据转换（JSON → Model 由 Repository 做）
- ❌ 不做请求组合（并发/串行调用多个接口是 Repository 的职责）
- ❌ 不处理 UI 相关逻辑

---

### 3.5 Entity 层（最内层）

**对应学术层：** Entities

**核心定位：** 纯粹的业务概念，是整个系统中最稳定的部分。不依赖任何框架或外部库。

**特征：**
- 只是数据结构（有时含核心业务规则方法）
- 与 Firebase、Flutter、AFNetworking 完全无关
- 变更最少，只有当业务概念本身改变时才修改

---

## 4. 实战场景：两个完整示例

### 场景一：登录功能（单接口，完整链路）

**各层代码示例（Flutter / ObjC 对照）：**

#### UI 层 — 只管交互，调用 UseCase

```dart
// Flutter
ElevatedButton(
  onPressed: () async {
    var result = await sl<LoginUseCase>().call(
      params: LoginReq(account: _account.text, password: _pwd.text),
    );
    result.fold(
      (error) => showSnackBar(error),   // 展示错误
      (user)  => Navigator.push(...),   // 跳转主页
    );
  },
  child: Text('登录'),
)
```

```objc
// iOS MVC
- (IBAction)loginBtnClicked:(id)sender {
    [self.loginUseCase executeWithAccount:self.accountTF.text
                                password:self.pwdTF.text
                              completion:^(User *user, NSError *error) {
        if (error) {
            [self showError:error.localizedDescription]; // 展示错误
        } else {
            [self pushToHomeVC];  // 跳转主页
        }
    }];
}
```

#### UseCase 层 — 业务校验 + 流程编排

```dart
// Flutter
class LoginUseCase implements UseCase<Either, LoginReq> {
  @override
  Future<Either> call({LoginReq? params}) async {
    // 1. 业务校验
    if (params!.account.isEmpty) return Left('账号不能为空');
    if (params.password.length < 6) return Left('密码至少6位');

    // 2. 调用 Repository（不直接调用 DataSource）
    final result = await sl<AuthRepository>().login(params);

    // 3. 业务后置处理：登录成功保存 Token
    result.fold(
      (error) => null,
      (user)  => TokenManager.save(user.token),
    );
    return result;
  }
}
```

```objc
// iOS
- (void)executeWithAccount:(NSString *)account password:(NSString *)pwd completion:(Completion)completion {
    // 1. 业务校验
    if (account.length == 0) {
        completion(nil, [NSError errorWithDomain:@"LoginError" code:-1
            userInfo:@{NSLocalizedDescriptionKey: @"账号不能为空"}]);
        return;
    }
    // 2. 调用 Repository
    [self.repo loginWithAccount:account password:pwd completion:^(User *user, NSError *error) {
        if (user) {
            // 3. 业务后置：保存 Token
            [TokenManager saveToken:user.token];
        }
        completion(user, error);
    }];
}
```

#### Repository 层 — 数据获取 + 格式转换

```dart
// Flutter
class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<Either> login(LoginReq req) async {
    // 调用 DataSource 获取原始数据，转换格式后返回
    return await sl<AuthDataSource>().requestLogin(req);
  }
}
```

```objc
// iOS — 数据转换（JSON → Model）在这里做
- (void)loginWithAccount:(NSString *)account password:(NSString *)pwd completion:(Completion)completion {
    [self.dataSource requestLogin:account pwd:pwd completion:^(NSDictionary *dict, NSError *error) {
        if (dict) {
            User *user = [[User alloc] initWithDict:dict]; // JSON → Model
            completion(user, nil);
        } else {
            completion(nil, error);
        }
    }];
}
```

#### DataSource 层 — 只管发请求，返回原始数据

```dart
// Flutter（Firebase 版本）
class AuthFirebaseServiceImpl extends AuthFirebaseService {
  @override
  Future<Either> signup(CreateUserReq req) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: req.email, password: req.password,
      );
      return const Right('Signup was Successful');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return Left('密码强度不足');
      if (e.code == 'email-already-in-use') return Left('邮箱已被注册');
      return Left('注册失败');
    }
  }
}
```

```objc
// iOS — 只发请求，返回原始 JSON
- (void)requestLogin:(NSString *)account pwd:(NSString *)pwd completion:(Completion)completion {
    NSDictionary *params = @{@"account": account, @"password": pwd};
    [[AFHTTPSessionManager manager] POST:@"/login" parameters:params
        success:^(NSURLSessionDataTask *task, id responseObject) {
            completion(responseObject, nil); // 原始 JSON，不做转换
        }
        failure:^(NSURLSessionDataTask *task, NSError *error) {
            completion(nil, error);
        }];
}
```

---

### 场景二：首页多接口并发加载

这个场景最能体现 Repository 和 DataSource 的职责差异。

#### UseCase 层 — 业务过滤

```dart
class LoadHomeDataUseCase {
  Future<HomeData> execute() async {
    // 1. 业务判断：用户是否登录
    if (!isLogin()) throw NotLoginException();

    // 2. 调用 Repository 拿组合后的数据（不关心数据怎么来的）
    final homeData = await sl<HomeRepository>().loadHomeAllData();

    // 3. 业务规则：过滤已读公告、下架商品
    homeData.notices  = homeData.notices.where((n) => !n.isRead).toList();
    homeData.products = homeData.products.where((p) => p.onSale).toList();

    return homeData;
  }
}
```

#### Repository 层 — 并发编排 + 数据组装

```dart
class HomeRepository {
  final HomeRemoteDataSource dataSource;

  Future<HomeData> loadHomeAllData() async {
    // 数据编排：并发调用 4 个 DataSource 接口
    final results = await Future.wait([
      dataSource.fetchUser(),
      dataSource.fetchConfig(),
      dataSource.fetchNotice(),
      dataSource.fetchProducts(),
    ]);

    // 数据组装：将零散原始数据拼成 UseCase 需要的 HomeData
    return HomeData(
      user:     results[0],
      config:   results[1],
      notices:  results[2],
      products: results[3],
    );
  }
}
```

#### DataSource 层 — 每个方法只做一个接口请求

```dart
class HomeRemoteDataSource {
  // 最小原子操作：一个方法只对应一个接口
  Future<User>          fetchUser()     => dio.get("/user");
  Future<Config>        fetchConfig()   => dio.get("/config");
  Future<Notice>        fetchNotice()   => dio.get("/notice");
  Future<List<Product>> fetchProducts() => dio.get("/products");
}
```

**对比说明：**

| 如果"多接口并发"放在 UseCase 做 | 如果"数据过滤"放在 Repository 做 |
|---|---|
| UseCase 需要知道有 4 个接口 | Repository 包含了业务规则 |
| UseCase 关心了"数据怎么来" | 违反了"数据层不做业务判断"原则 |
| ❌ 职责越界 | ❌ 职责越界 |

---

## 5. 本项目 Signup 功能对照

### 层级与文件映射

| 实践层 | 学术层 | 项目文件 | 关键职责 |
|---|---|---|---|
| UI 层 | Frameworks & Drivers | `lib/presentation/auth/pages/signup.dart` | 收集输入 → 调用 UseCase → fold 结果展示 |
| UseCase 层 | Use Cases | `lib/domain/usecases/auth/signup.dart` | 当前简单转发（可扩展校验逻辑） |
| Repository 接口 | Use Cases 边界 | `lib/domain/repository/auth/auth.dart` | 定义 Domain 层的数据契约（抽象接口） |
| Repository 实现 | Interface Adapters | `lib/data/repository/auth/auth_repository_impl.dart` | 实现接口，转发给 DataSource |
| DataSource | Frameworks & Drivers 数据端 | `lib/data/source/auth/auth_firebase_service.dart` | 调用 Firebase SDK，精准捕获异常 |
| Entity | Entities | `lib/domain/entities/auth/user.dart` | 纯业务用户对象，无框架依赖 |

### 完整调用链路

```
用户点击 "Create Account"
    │
    ▼ [UI 层]
SignupPage.onPressed()
  收集 fullName / email / password
  构造 CreateUserReq
  调用 sl<SignupUseCase>().call(params: req)
    │
    ▼ [UseCase 层]
SignupUseCase.call()
  [当前：直接转发；可扩展：在此加业务校验]
  调用 sl<AuthRepository>().signup(req)  ← 调用的是抽象接口
    │
    ▼ [Repository 层]
AuthRepositoryImpl.signup()
  实现 AuthRepository 接口
  调用 sl<AuthFirebaseService>().signup(req)
    │
    ▼ [DataSource 层]
AuthFirebaseServiceImpl.signup()
  FirebaseAuth.instance.createUserWithEmailAndPassword()
  精准捕获 FirebaseAuthException
  成功 → Right("Signup was Successful")
  失败 → Left("错误提示文字")
    │
    ▼ 结果反向传递回 UI 层
SignupPage.result.fold()
  Left  → SnackBar 错误提示
  Right → Navigator.pushAndRemoveUntil 跳转 RootPage
```

### Repository 接口为什么定义在 Domain 层？

这是整个架构中**最重要的一个设计决策**：

```
❌ 错误做法：接口定义在 Data 层
   Domain 层 import Data 层 → 内层依赖外层 → 违反依赖规则

✅ 正确做法：接口定义在 Domain 层
   Data 层 import Domain 层，实现其接口
   依赖方向：外层(Data) → 内层(Domain) ✅
```

这被称为**依赖倒置原则（DIP）**，效果是：Domain 层完全不知道 Firebase 的存在，只知道"我有一个可以 signup 的 Repository"。

---

## 6. 层间隔离的真实程度

### 当前项目：逻辑隔离（约定式）

本项目所有代码在**同一个 Dart 包**里，三层之间的隔离靠的是目录约定 + 开发纪律，没有编译器强制：

```dart
// 以下代码编译器不会报错，但严重违反架构约定
// SignupPage 越过 UseCase，直接调用 Firebase
import 'package:spotify/data/source/auth/auth_firebase_service.dart';
```

**GetIt 的角色：** 解决"运行时如何取到接口实例"，不是"编译期阻止越层访问"的门卫。

### 真正物理隔离的方案

| 方案 | 原理 | 适用场景 |
|---|---|---|
| **Melos 多包** | 每层独立 Dart Package，`pubspec.yaml` 控制依赖，编译期强制 | 中大型团队 |
| **Analyzer Lint 规则** | `dart_code_metrics` 的 `no-prohibited-import` 规则，静态分析拦截 | 小团队，低改造成本 |
| **Barrel File** | 每层只暴露 `export` 文件，未 export 的视为私有 | 过渡方案 |

当前项目作为学习 Demo，逻辑隔离完全合理；生产项目建议至少加 Analyzer Lint 规则。

---

## 7. 终极总结

### 一句话记住每一层

| 层 | 学术命名 | 一句话定义 | 绝对禁忌关键词 |
|---|---|---|---|
| UI 层 | Frameworks & Drivers | 只管界面和交互，不思考 | 不校验、不判断、不请求 |
| UseCase 层 | Use Cases | 只管业务规则，不碰数据细节 | 不发请求、不转换数据、不碰 UI |
| Repository 层 | Interface Adapters | 只管数据编排，不碰业务 | 不做业务判断、不直接发请求 |
| DataSource 层 | Frameworks & Drivers | 只管数据执行，不做判断 | 不做业务、不做转换、不做组合 |
| Entity 层 | Entities | 只是业务概念的纯数据表达 | 不 import 任何框架 |

### 核心价值

```
可替换性：Firebase → REST API → 只改 DataSource，其他层零修改
可测试性：UseCase 层用 Mock Repository，无需启动 Firebase 即可测试业务规则
可维护性：改业务逻辑只动 UseCase，改网络请求只动 DataSource，互不影响
多人协作：UI、业务、数据可由不同人同时开发，减少 Git 冲突
```
