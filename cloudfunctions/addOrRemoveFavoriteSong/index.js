'use strict';
const tcb = require('@cloudbase/node-sdk');

const app = tcb.init({ env: tcb.SYMBOL_CURRENT_ENV });
const db = app.database();

exports.main = async (event, context) => {
  const uid = context.OPENID;
  if (!uid) {
    return { code: 401, message: '用户未登录' };
  }

  const { songId } = event;
  if (!songId) {
    return { code: 400, message: 'songId 不能为空' };
  }

  const collection = db.collection('user_favorites');

  const queryRes = await collection.where({ uid }).get();

  if (queryRes.data.length === 0) {
    await collection.add({
      uid,
      _openid: uid,
      songIds: [songId],
    });
    return { code: 0, action: 'added', songId };
  }

  const doc = queryRes.data[0];
  const songIds = doc.songIds || [];
  const alreadyFavorite = songIds.includes(songId);

  if (alreadyFavorite) {
    await collection.doc(doc._id).update({
      songIds: db.command.pull(songId),
    });
    return { code: 0, action: 'removed', songId };
  } else {
    await collection.doc(doc._id).update({
      songIds: db.command.push(songId),
    });
    return { code: 0, action: 'added', songId };
  }
};
