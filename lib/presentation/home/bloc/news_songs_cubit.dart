import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spotify/domain/usecases/song/get_news_songs.dart';
import 'package:spotify/presentation/home/bloc/news_songs_state.dart';

import '../../../service_locator.dart';

class NewsSongsCubit extends Cubit<NewsSongsState> {
  NewsSongsCubit() : super(NewsSongsLoading());

  Future<void> getNewsSongs() async {
    var returnedSongs = await sl<GetNewsSongsUseCase>().call();

    returnedSongs.fold((error) => emit(NewsSongsLoadFailure()), (songs) {
      debugPrint('[getNewsSongs] ✅ 获取 ${songs.length} 首歌曲');
      emit(NewsSongsLoaded(songs: songs));
      for (final song in songs) {
        debugPrint(
          '  - ${song.title} / ${song.artist} (${song.releaseDate.toInt()})',
        );
      }
    });
  }
}
