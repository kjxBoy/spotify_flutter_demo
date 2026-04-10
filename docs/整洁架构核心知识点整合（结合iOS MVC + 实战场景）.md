# 整洁架构核心知识点整合（结合iOS MVC + 实战场景）

本文整合了近期关于整洁架构的核心疑问与解答，重点围绕“分层职责、UseCase/Repository/DataSource分工、iOS MVC适配”展开，结合实战场景（登录、首页多接口加载），帮你彻底理清整洁架构的落地逻辑，避免分层混淆。

# 一、整洁架构核心原则（基础前提）

整洁架构的核心是「分层解耦、依赖向内」，所有外层依赖内层，内层不依赖任何外层，核心目标是：让业务逻辑独立于框架、网络、数据库，实现“可维护、可测试、可迁移”。

核心分层（从外到内，依赖方向：外层→内层）：UI层 → UseCase层（业务逻辑层） → Repository层（数据仓库层） → DataSource层（数据源层）

注意：《整洁架构》书籍仅定义“分层原则和依赖方向”，并未明确UseCase、Repository等具体术语，这些术语是行业落地时形成的通用约定，目的是统一分层规范。

# 二、各分层核心职责（重中之重）

按“从外到内”顺序，明确每一层的核心工作、禁忌，结合实战场景说明，避免混淆。

## 1. 最外层：UI层（UseCase上层）

### 核心定位

iOS中对应「ViewController」，Flutter中对应「Page/Controller/Bloc」，是最薄、最干净的一层，仅负责“界面交互与展示”，不涉及任何业务逻辑。

### 具体职责（只做4件事）

- 响应用户操作：按钮点击、输入框输入、下拉刷新等（如登录按钮点击、首页刷新）；

- 调用UseCase：仅触发UseCase的执行，不关心UseCase的内部逻辑；

- 更新界面：接收UseCase返回的结果，展示数据（如显示用户信息、商品列表）或错误提示（如弹窗、Toast）；

- 页面跳转：如登录成功跳主页、退出登录跳登录页。

### 绝对禁忌

不做参数校验、不做业务判断、不发网络请求、不操作数据库，所有业务相关逻辑全部交给UseCase。

### iOS MVC中对应代码示例（登录页VC）

```objc
- (IBAction)loginBtnClicked:(id)sender {
    NSString *account = self.accountTF.text;
    NSString *pwd = self.pwdTF.text;

    // 仅调用UseCase，不写任何业务逻辑
    [self.loginUseCase executeWithAccount:account password:pwd completion:^(User *user, NSError *error) {
        if (error) {
            [self showError:error.localizedDescription]; // 更新UI（错误提示）
        } else {
            [self pushToHomeVC]; // 页面跳转
        }
    }];
}
```

## 2. 核心层：UseCase层（业务逻辑层）

### 核心定位

业务大脑，负责“业务规则、流程编排、参数校验”，是整洁架构的核心，独立于任何外部框架（网络、数据库）。

### 具体职责

- 参数校验：如登录时校验账号非空、密码长度≥6；

- 业务规则判断：如首页加载时过滤已读公告、下架商品，判断用户是否登录；

- 流程编排：调用Repository获取数据，对数据做业务层面的处理；

- 抛出业务异常：如“账号为空”“未登录”“余额不足”等业务相关异常；

- 简单业务后置处理：如登录成功后保存Token。

### 绝对禁忌

不发网络请求、不直接操作数据库、不做数据转换（JSON→Model）、不处理UI相关逻辑（如页面跳转、Toast）。

### 实战示例1：登录UseCase

```objc
@implementation LoginUseCase

- (void)executeWithAccount:(NSString *)account password:(NSString *)pwd completion:(Completion)completion {
    // 1. 业务校验（UseCase专属）
    if (account.length == 0) {
        NSError *error = [NSError errorWithDomain:@"LoginError" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"账号不能为空"}];
        completion(nil, error);
        return;
    }
    if (pwd.length < 6) {
        NSError *error = [NSError errorWithDomain:@"LoginError" code:-2 userInfo:@{NSLocalizedDescriptionKey:@"密码长度不能小于6位"}];
        completion(nil, error);
        return;
    }

    // 2. 调用Repository（不直接调用DataSource）
    [self.repo loginWithAccount:account password:pwd completion:^(User *user, NSError *error) {
        if (user) {
            // 3. 业务后置处理：保存Token
            [TokenManager saveToken:user.token];
        }
        completion(user, error);
    }];
}

@end
```

### 实战示例2：首页多接口加载UseCase（场景二）

```dart
class LoadHomeDataUseCase {
  final HomeRepository repo;

  Future<HomeData> execute() async {
    // 1. 业务判断：用户是否登录
    if (!isLogin()) {
      throw NotLoginException();
    }

    // 2. 调用仓库拿组合后的数据（不关心数据怎么来）
    final homeData = await repo.loadHomeAllData();

    // 3. 业务规则：过滤已读公告、下架商品
    homeData.notice = homeData.notice.where((n) => !n.read).toList();
    homeData.products = homeData.products.where((p) => p.onSale).toList();

    return homeData;
  }
}
```

## 3. 数据层：Repository层（数据仓库层）

### 核心定位

数据调度员，负责“数据编排、数据源选择、数据转换”，是UseCase和DataSource之间的桥梁，不涉及任何业务逻辑。

### 具体职责

- 调用DataSource：获取原始数据（网络请求、数据库读取）；

- 数据转换：将DataSource返回的原始数据（如JSON）转换为UseCase需要的Model（如User、HomeData）；

- 数据编排：组合多个DataSource的请求（如首页并发加载4个接口）；

- 缓存策略：决定数据从缓存读取还是网络读取，读取网络后同步缓存；

- 数据源切换：如开发环境/线上环境、模拟数据/真实数据的切换。

### 绝对禁忌

不做业务规则判断、不做参数校验、不直接发网络请求（交给DataSource）、不处理UI相关逻辑。

### 实战示例1：登录Repository

```objc
@implementation AuthRepository

- (void)loginWithAccount:(NSString *)account password:(NSString *)pwd completion:(Completion)completion {
    // 调用DataSource获取原始JSON数据
    [self.dataSource requestLogin:account pwd:pwd completion:^(NSDictionary *dict, NSError *error) {
        if (dict) {
            // 数据转换：JSON→Model
            User *user = [[User alloc] initWithDict:dict];
            completion(user, error);
        } else {
            completion(nil, error);
        }
    }];
}

@end
```

### 实战示例2：首页多接口加载Repository（场景二）

```dart
class HomeRepository {
  final HomeRemoteDataSource dataSource;

  Future<HomeData> loadHomeAllData() async {
    // 数据编排：并发调用4个DataSource接口
    final results = await Future.wait([
      dataSource.fetchUser(),
      dataSource.fetchConfig(),
      dataSource.fetchNotice(),
      dataSource.fetchProducts(),
    ]);

    // 数据转换+组装：将零散数据拼成UseCase需要的HomeData
    return HomeData(
      user: results[0],
      config: results[1],
      notice: results[2],
      products: results[3],
    );
  }
}
```

## 4. 最底层：DataSource层（数据源层）

### 核心定位

真正的“数据执行者”，负责与外部系统打交道（网络、数据库、本地缓存），是整洁架构的最底层，只做最小粒度的数据操作。

### 具体职责

- 网络请求：用AFNetworking、Alamofire、Dio等框架发请求，获取原始数据（JSON）；

- 本地数据操作：读取/写入数据库、SharedPreferences、本地文件；

- 最小原子操作：每个方法只做一件事（如一个接口对应一个方法），不组合、不判断。

### 绝对禁忌

不做业务逻辑、不做数据转换、不做请求组合、不处理UI相关逻辑。

### 实战示例1：登录DataSource

```objc
@implementation AuthRemoteDataSource

- (void)requestLogin:(NSString *)account pwd:(NSString *)pwd completion:(Completion)completion {
    // 真正的网络请求（仅在这里写）
    NSDictionary *params = @{@"account": account, @"password": pwd};
    [AFHTTPSessionManager manager] POST:@"/login" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completion(responseObject, nil);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completion(nil, error);
    }];
}

@end
```

### 实战示例2：首页多接口DataSource（场景二）

```dart
class HomeRemoteDataSource {
  // 每个方法只做一个接口请求（最小原子操作）
  Future<User> fetchUser() => dio.get("/user");
  Future<Config> fetchConfig() => dio.get("/config");
  Future<Notice> fetchNotice() => dio.get("/notice");
  Future<List<Product>> fetchProducts() => dio.get("/products");
}
```

# 三、iOS MVC与整洁架构的适配（关键落地）

整洁架构不推翻iOS MVC，而是对MVC进行“优化拆分”，解决传统MVC中“ViewController臃肿、Model层混乱”的问题，适配后结构如下：

## 适配对应关系

- iOS MVC的「View」→ 整洁架构的「UI层（View部分）」：负责界面展示，不做逻辑；

- iOS MVC的「ViewController」→ 整洁架构的「UI层（Controller部分）」：变轻，只做交互、调用UseCase、更新UI；

- iOS MVC的「Model层」→ 拆分为3层：UseCase层（业务逻辑）、Repository层（数据调度）、DataSource层（数据执行）。

## 适配后核心优势

传统MVC的问题：ViewController包揽所有逻辑（UI、业务、网络），Model层一锅炖；适配后：

- ViewController不再臃肿（代码量减少70%），维护成本降低；

- 业务逻辑独立，可复用、可测试；

- 数据层与业务层解耦，换网络框架、数据库时，不影响业务逻辑。

# 四、常见疑问解答（避坑重点）

## 1. 为什么Repository和DataSource看起来很统一？

仅在「简单场景」（如单一网络请求，无缓存、无多接口组合）下，两者看似重复（Repository仅转发请求）；但在复杂场景下，职责差异立刻体现：

- 有缓存：Repository判断“读缓存还是读网络”，DataSource只负责读缓存/网络；

- 多接口组合：Repository负责并发/串行调用多个DataSource接口，组装数据；

- 数据源切换：Repository选择用哪个DataSource（开发/线上、模拟/真实）。

本质区别：DataSource是“零件”（最小数据操作），Repository是“组装工人”（数据编排、策略）。

## 2. 小项目需要分这么多层吗？

如果确定项目「永远简单」（无复杂业务、无多数据源、无扩展需求），可以将Repository和DataSource合并一层，简化结构；但行业规范分层，是因为项目会逐渐复杂（加缓存、加业务规则、换框架），提前分层能避免后期代码变成“屎山”。

## 3. 分层后代码变多，是不是更麻烦？

前期确实会增加代码量、文件量，看似麻烦，但后期收益巨大：

- 维护简单：改业务逻辑只动UseCase，改网络请求只动DataSource，不影响其他层；

- 复用性强：一个UseCase可被多个ViewController调用（如登录UseCase可用于登录页、自动登录）；

- 测试便捷：不用启动App、不用模拟器，直接对UseCase做单元测试，验证业务规则；

- 多人协作：UI、业务、数据层可由不同人开发，互不干扰，减少Git冲突。

# 五、终极总结（一句话记牢）

- UI层：只管界面和交互，不思考；

- UseCase层：只管业务规则，不碰数据细节；

- Repository层：只管数据编排，不碰业务；

- DataSource层：只管数据执行，不做判断。

核心目标：让业务逻辑“脱离框架束缚”，实现可维护、可测试、可迁移，项目越大，分层的价值越明显。
> （注：文档部分内容可能由 AI 生成）