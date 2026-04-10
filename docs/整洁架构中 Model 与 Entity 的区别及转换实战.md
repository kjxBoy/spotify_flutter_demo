# 整洁架构中 Model 与 Entity 的区别及转换实战

本文整合 Model 与 Entity 的核心区别、职责划分、代码示例，以及整洁架构中的转换逻辑和数据流，结合之前的分层架构（UseCase/Repository/DataSource），帮你彻底分清两者的定位，掌握标准转换写法，可直接套用于项目开发。

# 一、核心定义与终极区分

在整洁架构和领域驱动设计（DDD）中，Model 与 Entity 是两个截然不同的概念，核心定位和职责完全分离，一句话可快速区分：

Entity（领域实体）：有属性、有行为、有业务规则，是业务核心，放于内层；
Model（数据模型）：只有属性、无行为，仅作为数据载体，放于外层。

## 形象比喻（快速理解）

- Entity = 一个活人：有行为（吃饭、跑步）、有规则（不能空腹喝酒）、有状态（成年/未成年）；

- Model = 活人的身份证/档案：只有基础信息（姓名、年龄、身份证号），无任何行为和规则判断。

# 二、核心区别（3点彻底分清）

|对比维度|Entity（领域实体）|Model（数据模型）|
|---|---|---|
|是否有行为|有业务方法、有业务规则判断（如判断是否成年、能否操作）|无任何行为，只有属性和 JSON 转换方法（fromJson/toJson）|
|所处分层|领域层（内层，整洁架构核心），不依赖任何外层|数据层/UI层（外层），用于网络请求、数据库映射、页面展示|
|依赖关系|不依赖 Model，完全独立于外部框架和数据格式|可被转换为 Entity，依赖后端接口字段、数据库结构|
|核心作用|承载业务逻辑，供 UseCase 调用做业务判断|承载数据传输，实现 JSON 与对象的转换、数据存储与展示|
# 三、完整代码示例（可直接复用）

以下示例贴合整洁架构分层，包含 Entity 定义、Model 定义、Model→Entity 转换，以及 UseCase/Repository 中的使用场景，统一以“用户信息”为例。

## 1. Entity（领域实体，内层）

纯业务属性 + 业务方法，不涉及任何 JSON、网络、数据库相关逻辑，完全独立。

```dart
/// 领域实体：UserEntity（业务核心）
class UserEntity {
  final String id;
  final String username;
  final int age;
  final bool isVip;

  // 构造方法：仅接收业务属性，不处理任何数据转换
  UserEntity({
    required this.id,
    required this.username,
    required this.age,
    required this.isVip,
  });

  /// 业务行为1：判断是否成年（核心业务规则）
  bool isAdult() {
    return age >= 18;
  }

  /// 业务行为2：判断能否观看限制内容（组合业务规则）
  bool canWatchRestricted() {
    return isAdult() && isVip;
  }

  /// 可选：业务行为3：修改用户名（体现“状态变化”）
  UserEntity updateUsername(String newUsername) {
    return UserEntity(
      id: this.id,
      username: newUsername,
      age: this.age,
      isVip: this.isVip,
    );
  }
}
```

## 2. Model（数据模型，外层）

仅负责数据承载和 JSON 序列化，无任何业务逻辑，字段需与后端接口、数据库字段对应。

```dart
/// 数据模型：UserModel（网络/数据库专用）
class UserModel {
  final String id;
  final String username;
  final int age;
  final bool isVip;

  // 构造方法：仅初始化属性
  UserModel({
    required this.id,
    required this.username,
    required this.age,
    required this.isVip,
  });

  /// 核心：JSON 转 Model（适配后端接口字段）
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '', // 字段容错，避免空指针
      username: json['username'] ?? '',
      age: json['age'] ?? 0,
      isVip: json['is_vip'] ?? false, // 后端字段可能是下划线命名，与Model属性对应
    );
  }

  /// 可选：Model 转 JSON（用于提交数据给后端）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'age': age,
      'is_vip': isVip,
    };
  }

  /// 快捷方法：Model 转 Entity（简化 Repository 中的转换逻辑）
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      username: username,
      age: age,
      isVip: isVip,
    );
  }
}
```

## 3. Model → Entity 转换（核心：写在 Repository 中）

整洁架构的规范要求：Repository 作为数据层与业务层的桥梁，负责将外层的 Model 转换为内层的 Entity，供 UseCase 调用。

```dart
/// UserRepository（数据仓库层）
class UserRepository {
  final UserRemoteDataSource dataSource; // 数据源（网络/数据库）

  // 依赖注入：通过构造方法传入 DataSource，降低耦合
  UserRepository(this.dataSource);

  /// 示例：获取用户信息，完成 Model → Entity 转换
  Future<UserEntity> getUserInfo(String userId) async {
    // 1. 从 DataSource 获取 Model（纯数据，来自网络/数据库）
    final UserModel userModel = await dataSource.getUserInfo(userId);

    // 2. Model 转 Entity（两种方式，选一种即可）
    // 方式1：直接转换（适合字段较少的场景）
    // return UserEntity(
    //   id: userModel.id,
    //   username: userModel.username,
    //   age: userModel.age,
    //   isVip: userModel.isVip,
    // );

    // 方式2：调用 Model 中的 toEntity 方法（更简洁，推荐）
    return userModel.toEntity();
  }

  /// 示例：修改用户名（体现 Entity → Model 转换，用于提交数据）
  Future<bool> updateUsername(String userId, String newUsername) async {
    // 1. 获取当前用户 Entity
    final UserEntity currentUser = await getUserInfo(userId);
    // 2. 调用 Entity 的业务方法，修改用户名（状态变化）
    final UserEntity updatedUser = currentUser.updateUsername(newUsername);
    // 3. Entity 转 Model（用于提交给后端）
    final UserModel updatedModel = UserModel(
      id: updatedUser.id,
      username: updatedUser.username,
      age: updatedUser.age,
      isVip: updatedUser.isVip,
    );
    // 4. 调用 DataSource 提交数据
    return await dataSource.updateUsername(userId, updatedModel.toJson());
  }
}
```

## 4. UseCase 中使用 Entity（业务层）

UseCase 仅依赖 Entity，完全不知道 Model 的存在，所有业务逻辑基于 Entity 实现。

```dart
/// GetUserInfoUseCase（业务逻辑层）
class GetUserInfoUseCase {
  final UserRepository repo;

  GetUserInfoUseCase(this.repo);

  Future<UserEntity> execute(String userId) async {
    // 1. 调用 Repository 获取 Entity（不接触 Model）
    final UserEntity userEntity = await repo.getUserInfo(userId);

    // 2. 使用 Entity 的业务方法做业务判断
    if (!userEntity.isAdult()) {
      throw UnderAgeException(message: "用户未满18岁，无法操作");
    }
    if (!userEntity.canWatchRestricted()) {
      throw VipRequiredException(message: "需开通VIP才能观看限制内容");
    }

    // 3. 返回 Entity，供 UI 层使用（UI层可再转成展示专用模型）
    return userEntity;
  }
}
```

## 5. DataSource 中返回 Model（数据源层）

DataSource 负责与外部系统（网络、数据库）交互，返回的是 Model（纯数据），不涉及任何业务逻辑和 Entity 转换。

```dart
/// UserRemoteDataSource（数据源层，网络请求）
class UserRemoteDataSource {
  final Dio dio;

  UserRemoteDataSource(this.dio);

  /// 获取用户信息：返回 Model（纯数据）
  Future<UserModel> getUserInfo(String userId) async {
    final response = await dio.get("/user/$userId");
    // JSON 转 Model，直接返回 Model
    return UserModel.fromJson(response.data);
  }

  /// 修改用户名：接收 Model 转的 JSON 提交
  Future<bool> updateUsername(String userId, Map<String, dynamic> params) async {
    final response = await dio.put("/user/$userId", data: params);
    return response.statusCode == 200;
  }
}
```

# 四、整洁架构中的数据流（关键）

Model 与 Entity 的转换，是整洁架构“依赖向内”原则的核心体现，完整数据流如下（从外到内，再从内到外）：

1. DataSource（外层）：调用网络/数据库，返回 UserModel（纯数据）；
2. Repository（中间层）：将 UserModel 转换为 UserEntity；
3. UseCase（内层）：调用 UserEntity 的业务方法，做业务逻辑判断；
4. UI层（外层）：接收 UseCase 返回的 UserEntity，可转成 UI 展示专用模型（如 VO），渲染页面；
5. 提交数据时：UI层/UseCase 生成 Entity → Repository 转成 Model → DataSource 提交给后端。

# 五、为什么要区分 Model 与 Entity？（核心好处）

1. 保护业务逻辑不被污染：Entity 在内层，不依赖任何外部框架（网络、JSON、数据库），后端改接口字段、换网络框架，只需修改 Model，不影响 Entity 和业务逻辑；

2. 职责明确，降低耦合：Model 只管数据传输，Entity 只管业务逻辑，分层清晰，后期维护、修改更便捷；

3. 提升代码复用性：Entity 可被多个 UseCase 调用，Model 可适配不同数据源（网络、数据库），无需重复编写逻辑；

4. 便于测试：Entity 可独立做单元测试（无需启动网络、数据库），验证业务规则的正确性。

# 六、终极总结（一句话记牢）

- Entity 是“活的”：有行为、有规则，是业务的核心；

- Model 是“死的”：只有数据、无行为，是数据的载体；

- Repository 是“翻译官”：负责 Model 与 Entity 的双向转换，隔离外层数据与内层业务。

简单来说：项目中带业务方法、业务规则的叫 Entity，只用来解析 JSON、传数据的叫 Model。
> （注：文档部分内容可能由 AI 生成）