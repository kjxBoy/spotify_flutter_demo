'use strict';
const tcb = require('@cloudbase/node-sdk');

const app = tcb.init({ env: tcb.SYMBOL_CURRENT_ENV });
const db = app.database();

exports.main = async (event, context) => {
  const uid = context.OPENID;
  if (!uid) {
    return { code: 401, message: '用户未登录' };
  }

  const favRes = await db.collection('user_favorites').where({ uid }).get();

  if (favRes.data.length === 0) {
    return { code: 0, data: [] };
  }

  const songIds = favRes.data[0].songIds || [];
  if (songIds.length === 0) {
    return { code: 0, data: [] };
  }

  const songsRes = await db
    .collection('songs')
    .where({ _id: db.command.in(songIds) })
    .get();

  return {
    code: 0,
    data: songsRes.data,
    total: songsRes.data.length,
  };
};
