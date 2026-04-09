import 'package:dartz/dartz.dart';
import 'package:spotify/core/usecase/usecase.dart';
import 'package:spotify/data/models/auth/create_user_req.dart';
import 'package:spotify/domain/repository/auth/auth.dart';

import '../../../service_locator.dart';

/*
*
* 在干净架构、领域驱动设计（DDD）、Flutter / 后端业务开发里，UseCase（用例） 一般指：
* 专门处理 “一个业务动作” 的逻辑层，是业务逻辑的核心载体。
*
* 它不负责 UI、不负责数据库、不负责网络，
* 只做一件事：接收参数 → 调用仓库 / 服务 → 返回结果。
* */

class SignupUseCase implements UseCase<Either,CreateUserReq> {

  @override
  Future<Either> call({CreateUserReq ? params}) async {
    return sl<AuthRepository>().signup(params!);
  }

}