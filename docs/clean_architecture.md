# Clean Architecture 架构设计文档

> 本文档先从理论层面阐述 Clean Architecture 各层的本质定义与职责边界，再以本项目「注册（Signup）」功能为例，验证理论在实际代码中的落地方式。

---

## 目录

1. [Clean Architecture 理论基础](#1-clean-architecture-理论基础)
2. [四层模型的本质定义](#2-四层模型的本质定义)
3. [层间边界的核心原则](#3-层间边界的核心原则)
4. [项目实现对照分析](#4-项目实现对照分析)
5. [层间隔离的真实程度](#5-层间隔离的真实程度)
6. [架构设计总结](#6-架构设计总结)

---

## 1. Clean Architecture 理论基础

Clean Architecture（整洁架构）由 Robert C. Martin（Uncle Bob）在 2012 年提出，其本质是一种**关注点分离**的架构思想，目标是让系统的每个部分都只关注"自己该做的事"。

核心思想可以用一句话概括：

> **业务规则（Business Rules）不应依赖于任何实现细节（数据库、UI 框架、网络库）。**

这意味着当你切换数据库、替换 UI 框架、改变网络请求方式时，业务规则代码**一行都不应该改动**。

---

## 2. 四层模型的本质定义

标准 Clean Architecture 分为四层，从内到外依次是：

```
┌─────────────────────────────────────────────┐
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │                                     │   │
│   │   ┌─────────────────────────────┐   │   │
│   │   │                             │   │   │
│   │   │   ┌─────────────────────┐   │   │   │
│   │   │   │    Entities（实体）   │   │   │   │
│   │   │   └─────────────────────┘   │   │   │
│   │   │       Use Cases（用例）      │   │   │
│   │   └─────────────────────────────┘   │   │
│   │    Interface Adapters（接口适配器）   │   │
│   └─────────────────────────────────────┘   │
│        Frameworks & Drivers（框架与驱动）     │
└─────────────────────────────────────────────┘
```

**依赖规则（Dependency Rule）：** 源代码的依赖方向只能由外向内，内层对外层一无所知。

---

### 2.1 Entities — 实体层（最内层）

**理论定义：**  
实体封装了**企业级业务规则**，是整个系统中最稳定的部分。它们是纯粹的业务概念，与任何框架、数据库、UI 都无关。

**关键特征：**
- 只是数据结构 + 关键业务规则的集合
- 变更最少：只有当企业核心业务概念发生变化时才会改动
- 零外部依赖：不 import 任何框架或库

**本项目对应：** `lib/domain/entities/auth/user.dart`

```dart
// 纯 Dart 对象，代表业务中的"用户"概念
// 无 Firebase User、无 Flutter Widget、无 JSON 序列化
class UserEntity {
  String? userId;
  String? fullName;
  String? email;
}
```

---

### 2.2 Use Cases — 用例层（业务逻辑层）

**理论定义：**  
用例封装了**应用级业务规则**，即「系统能做什么」。每个 UseCase 代表一个独立的用户意图（User Story），是业务逻辑的核心载体。

**关键特征：**
- 每个 UseCase 只做一件事（Single Responsibility）
- 编排 Entities 和 Repository 接口来完成业务目标
- 不知道数据从哪里来（不知道是 Firebase、REST 还是本地数据库）
- 不知道结果如何展示（不知道是 Flutter、Web 还是命令行）

**UseCase 的标准行为模式：**

```
接收 输入 (Input Port / Request Model)
    ↓
执行 业务规则（可能包含校验、计算、状态判断）
    ↓
调用 Repository 接口（获取/存储数据）
    ↓
返回 输出 (Output Port / Response Model)
```

**本项目对应：** `lib/domain/usecases/auth/signup.dart`

```dart
class SignupUseCase implements UseCase<Either, CreateUserReq> {
  @override
  Future<Either> call({CreateUserReq? params}) async {
    // 当前仅做简单转发，业务扩展时此处添加规则（格式校验、黑名单检查等）
    return sl<AuthRepository>().signup(params!);
  }
}
```

UseCase 的泛型基类约束了统一接口：

```dart
// 所有 UseCase 必须实现 call() 方法
// Type = 返回类型，Params = 输入参数类型
abstract class UseCase<Type, Params> {
  Future<Type> call({Params params});
}
```

---

### 2.3 Interface Adapters — 接口适配层

**理论定义：**  
接口适配层负责将内层（Use Cases / Entities）的数据格式，转换为外层（框架、数据库、UI）能理解的格式，反之亦然。这一层充当**防腐层（Anti-Corruption Layer）**。

这一层在不同架构风格中有不同的叫法：

| 方向 | 组件名 | 职责 |
|---|---|---|
| 数据流入方向 | Repository Impl | 将 DB/API 数据转换为 Domain Entity |
| 数据流出方向 | Presenter / ViewModel | 将 Domain Entity 转换为 UI 需要的展示模型 |
| 控制流入方向 | Controller / UseCase Invoker | 接收 UI 事件，调用对应 UseCase |

**本项目对应：**
- `lib/data/repository/auth/auth_repository_impl.dart` — 实现 Domain 层的 Repository 接口
- `lib/domain/repository/auth/auth.dart` — 定义接口契约（边界协议）

```dart
// 接口（定义在 Domain 层）— 描述"能做什么"
abstract class AuthRepository {
  Future<Either> signup(CreateUserReq createUserReq);
  Future<void> signin();
}

// 实现（定义在 Data 层）— 描述"怎么做"
class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<Either> signup(CreateUserReq createUserReq) async {
    return await sl<AuthFirebaseService>().signup(createUserReq);
  }
}
```

---

### 2.4 Frameworks & Drivers — 框架与驱动层（最外层）

**理论定义：**  
这是最外层，包含所有的框架、工具、数据库驱动、UI 框架等外部细节。这一层通常只是"胶水代码"——将外部世界与内层系统连接起来。

**关键特征：**
- 变化最频繁（框架升级、数据库迁移、UI 重写）
- 对内层系统影响最小（因为内层不依赖它）
- 包含具体的技术实现细节

**本项目对应两个部分：**

**UI 端（Flutter 框架）：** `lib/presentation/auth/pages/signup.dart`

```dart
// Flutter Widget、TextEditingController、Navigator、SnackBar
// 这些都是"框架细节"，放在最外层
class SignupPage extends StatelessWidget { ... }
```

**数据端（Firebase SDK）：** `lib/data/source/auth/auth_firebase_service.dart`

```dart
// Firebase SDK 只在这一层出现
// FirebaseAuth.instance 是"外部驱动"
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: createUserReq.email,
  password: createUserReq.password,
);
```

---

## 3. 层间边界的核心原则

### 3.1 依赖规则（The Dependency Rule）

**唯一铁律：** 依赖方向只能从外层指向内层，不可逆。

```
外层可以知道内层存在   ✅
内层绝对不能知道外层   ❌
```

**在代码层面的体现：** 内层的 `import` 语句里，永远不会出现外层的包路径。

```
domain/repository/auth/auth.dart  ← 这里不会有 firebase_auth 的 import
domain/usecases/auth/signup.dart  ← 这里不会有 flutter/material.dart 的 import
```

### 3.2 跨层通信的两种方式

**向内调用（控制流向内）：**

```
UI 调用 UseCase  →  UseCase 调用 Repository接口  →  RepositoryImpl 调用 Firebase
```

这是正向数据流，外层"调用"内层，没有任何问题。

**向外返回（数据流向外）：**

数据从内到外时，如果直接传递内层对象给外层，就会产生反向依赖。标准解法是**在边界处转换数据格式**：

```
Firebase 返回 Firebase User 对象
    ↓ Data 层转换
返回 Either<String, String>（本项目当前实现）
或 UserEntity（更标准的 Domain 实体）
    ↓ Presentation 层消费
UI 只看到纯粹的成功/失败信息
```

### 3.3 接口的方向性

**Repository 接口定义在 Domain 层**，这是整个架构中最重要的设计决策：

```
❌ 错误做法：接口定义在 Data 层
  Data 层定义 → Domain 层依赖 Data 层 → 违反依赖规则

✅ 正确做法：接口定义在 Domain 层
  Domain 层定义接口 → Data 层实现接口 → Data 层依赖 Domain 层
  依赖方向：外层(Data) → 内层(Domain) ✅
```

这个设计被称为**依赖倒置原则（Dependency Inversion Principle，DIP）**。

---

## 4. 项目实现对照分析

将理论层与项目文件进行完整映射：

### 4.1 层级映射表

| 理论层 | 本项目目录 | 关键文件 | 对应的"变化原因" |
|---|---|---|---|
| Entities | `lib/domain/entities/` | `user.dart` | 业务概念变化（极少）|
| Use Cases | `lib/domain/usecases/` | `signup.dart` | 业务需求变化（偶尔）|
| Interface Adapters | `lib/domain/repository/`（接口） `lib/data/repository/`（实现） | `auth.dart` `auth_repository_impl.dart` | 数据聚合方式变化 |
| Frameworks & Drivers | `lib/presentation/` `lib/data/source/` | `signup.dart`（UI） `auth_firebase_service.dart`（数据源）| UI 设计变化 / Firebase 升级 |

### 4.2 Signup 功能完整数据流

```
[用户点击 "Create Account"]
         │
         ▼ ① UI 事件（Frameworks & Drivers 层）
┌────────────────────────────────────┐
│  SignupPage                        │
│  收集 fullName / email / password   │
│  构造 CreateUserReq                 │
│  调用 sl<SignupUseCase>().call()    │
└────────────────┬───────────────────┘
                 │ ② 跨越层边界（Frameworks → Use Cases）
                 ▼
┌────────────────────────────────────┐
│  SignupUseCase（Use Cases 层）      │
│  接收 CreateUserReq                 │
│  [此处可插入业务校验规则]             │
│  调用 sl<AuthRepository>().signup() │
└────────────────┬───────────────────┘
                 │ ③ 跨越层边界（Use Cases → Interface Adapters）
                 ▼
┌────────────────────────────────────┐
│  AuthRepository（接口定义）          │
│  → AuthRepositoryImpl（实现）        │
│  调用 sl<AuthFirebaseService>()     │
└────────────────┬───────────────────┘
                 │ ④ 跨越层边界（Interface Adapters → Frameworks）
                 ▼
┌────────────────────────────────────┐
│  AuthFirebaseServiceImpl           │
│  FirebaseAuth.instance             │
│  .createUserWithEmailAndPassword() │
│                                    │
│  成功 → Right("Signup Successful") │
│  失败 → Left("错误描述")             │
└────────────────┬───────────────────┘
                 │ ⑤ Either 结果反向传递
                 ▼
┌────────────────────────────────────┐
│  SignupPage.result.fold()          │
│  Left  → SnackBar 错误提示          │
│  Right → Navigator 跳转 RootPage   │
└────────────────────────────────────┘
```

### 4.3 错误处理的架构位置

`Either<Left, Right>` 是一种**函数式错误处理**模式，替代传统 try/catch，让错误成为返回值的一部分：

```
                  FirebaseAuthException
                  在 Data 层被精准捕获
                         │
                         ▼
                  转换为 Left(message)  ← Firebase 的错误细节被封装在这里
                         │
    Either 沿调用链向上传递，每一层透明传递
                         │
                         ▼
               Presentation 层 fold()  ← UI 只看到"错误文字"，不知道是 Firebase 错误
```

**关键设计价值：**  
`FirebaseAuthException` 这个 Firebase 专属类型，在 Data 层就被"消化"了，转换为与框架无关的字符串 `Left(message)`。Domain 层和 Presentation 层完全不知道 `FirebaseAuthException` 的存在。

---

## 5. 层间隔离的真实程度

### 5.1 当前项目：逻辑隔离（Convention-Based）

本项目所有代码在**同一个 Dart 包**中，层间隔离依赖**目录约定 + 开发纪律**：

```
lib/
├── presentation/   ─┐
├── domain/          ├── 同一个包，编译器无法强制隔离
└── data/           ─┘
```

这意味着，以下代码在 Dart 编译器层面**完全合法**，不会报任何错误：

```dart
// ❌ 违反架构约定，但编译通过
// SignupPage 越过 UseCase，直接调用 Firebase Service
import 'package:spotify/data/source/auth/auth_firebase_service.dart';
```

GetIt 的本质角色是**运行时依赖解析**，而非**编译时层间门卫**：

| GetIt 能做的 | GetIt 做不到的 |
|---|---|
| 运行时返回正确的接口实现 | 阻止开发者越层 import |
| 用接口类型隐藏实现细节 | 编译期强制层间访问规则 |
| 单例管理对象生命周期 | 防止架构腐化 |

### 5.2 物理隔离的实现方式

**方案一：Melos 多包架构（生产项目推荐）**

将每一层拆分为独立的 Dart Package，通过 `pubspec.yaml` 的依赖声明来物理阻断越层引用：

```
packages/
├── domain/        # pubspec.yaml: 零外部依赖
├── data/          # pubspec.yaml: dependencies: domain
└── presentation/  # pubspec.yaml: dependencies: domain
                   # ❌ data 不在依赖里 → 无法 import data 层任何内容
```

**方案二：Analyzer 静态分析规则（低成本）**

在 `analysis_options.yaml` 中配置导入限制：

```yaml
# 使用 dart_code_metrics 包
dart_code_metrics:
  rules:
    - no-prohibited-import:
        forbidden:
          - from: "lib/presentation/**"
            to: "lib/data/**"
            message: "Presentation 层不能直接访问 Data 层"
          - from: "lib/domain/**"
            to: "lib/data/**"
            message: "Domain 层不能依赖 Data 层"
```

**本项目的合理性：** 作为学习 Demo，逻辑隔离已经清晰表达了架构意图；真实生产项目应根据团队规模选择物理隔离方案。

---

## 6. 架构设计总结

### 各层核心职责一句话总结

| 层 | 核心问题 | 一句话总结 |
|---|---|---|
| Entities | 业务是什么？ | 描述业务世界中存在的"人和物" |
| Use Cases | 系统能做什么？ | 编排业务动作，表达用户意图 |
| Interface Adapters | 数据如何转换？ | 在不同格式之间翻译，充当防腐层 |
| Frameworks & Drivers | 技术细节怎么实现？ | 胶水代码，连接系统与外部世界 |

### Clean Architecture 的核心价值

```
可替换性：
  更换 Firebase → 只改 Data 层
  重写 UI → 只改 Presentation 层
  调整业务规则 → 只改 Domain 层

可测试性：
  Domain 层测试：Mock Repository 接口，无需启动 Firebase
  Data 层测试：集成测试，真实网络请求
  Presentation 层测试：Widget Test，Mock UseCase

可维护性：
  每个文件只有一个变化原因（SRP）
  业务逻辑集中在 UseCase，不散落在 UI 代码里
  错误处理在 Data 层统一处理，UI 层只负责展示
```

### 这套架构最重要的设计决策

> **Repository 接口定义在 Domain 层，而不是 Data 层。**

这一个决策，将 Data 层从「被依赖的」变成了「依赖别人的」，从根本上保证了业务核心（Domain 层）的独立性与稳定性。这是整个 Clean Architecture 的精髓所在。
