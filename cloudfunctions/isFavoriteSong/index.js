'use strict';
const tcb = require('@cloudbase/node-sdk');

const app = tcb.init({ env: tcb.SYMBOL_CURRENT_ENV });
const db = app.database();
const auth = app.auth();

exports.main = async (event, context) => {
  const { uid } = auth.getUserInfo();
  if (!uid) {
    return { code: 401, message: '用户未登录', isFavorite: false };
  }

  const { songId } = event;
  if (!songId) {
    return { code: 400, message: 'songId 不能为空', isFavorite: false };
  }

  const res = await db.collection('user_favorites').where({ uid }).get();

  if (res.data.length === 0) {
    return { code: 0, isFavorite: false };
  }

  const songIds = res.data[0].songIds || [];
  return { code: 0, isFavorite: songIds.includes(songId) };
};
