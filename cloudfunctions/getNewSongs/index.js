'use strict';
const tcb = require('@cloudbase/node-sdk');

const app = tcb.init({ env: tcb.SYMBOL_CURRENT_ENV });
const db = app.database();
const auth = app.auth();

exports.main = async (event) => {
  const limit = event.limit ?? 50;
  const skip = event.skip ?? 0;

  const res = await db
    .collection('songs')
    .orderBy('releaseDate', 'desc')
    .skip(skip)
    .limit(limit)
    .get();

  let favoriteSongIds = [];
  const { uid } = auth.getUserInfo();
  if (uid) {
    const favRes = await db.collection('user_favorites').where({ uid }).get();
    if (favRes.data.length > 0) {
      favoriteSongIds = favRes.data[0].songIds || [];
    }
  }

  const data = res.data.map((song) => ({
    ...song,
    isFavorite: favoriteSongIds.includes(song._id),
  }));

  return {
    data,
    total: data.length,
  };
};
