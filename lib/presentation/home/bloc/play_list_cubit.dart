import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spotify/domain/usecases/song/get_play_list.dart';
import 'package:spotify/presentation/home/bloc/play_list_state.dart';

import '../../../domain/usecases/song/get_news_songs.dart';
import '../../../service_locator.dart';

class PlayListCubit extends Cubit<PlayListState> {
  PlayListCubit() : super(PlayListLoading());

  Future<void> getPlayList() async {
    var playList = await sl<GetPlayListUseCase>().call();

    playList.fold(
      (error) => emit(PlayListLoadFailure()),
      (songs) => emit(PlayListLoaded(songs: songs)),
    );
  }
}
