import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spotify/domain/usecases/song/get_news_songs.dart';
import 'package:spotify/presentation/home/bloc/news_songs_state.dart';

import '../../../service_locator.dart';

// 主线程时间线 ──────────────────────────────────────────────→

// getNewsSongs() 被调用
//     │
//     ├─ await 开始 → 发出网络请求，函数"挂起"
//     │                │
//     │                │  ← 主线程继续：UI渲染、动画...
//     │                │  ← BlocBuilder 显示 CircularProgressIndicator
//     │                │
//     │                │（网络耗时：300ms ～ 2000ms）
//     │                │
//     │◄──────────────── 网络返回，函数从 await 处恢复
//     │
//     ├─ returnedSongs.fold(...)
//     └─ emit(NewsSongsLoaded) → BlocBuilder 重建 → 渲染歌曲列表

class NewsSongsCubit extends Cubit<NewsSongsState> {
  NewsSongsCubit() : super(NewsSongsLoading());

  Future<void> getNewsSongs() async {
    var returnedSongs = await sl<GetNewsSongsUseCase>().call();

    returnedSongs.fold(
      (error) => emit(NewsSongsLoadFailure()),
      (songs) => emit(NewsSongsLoaded(songs: songs)),
    );
  }
}
