'use strict';
const tcb = require('@cloudbase/node-sdk');

const app = tcb.init({ env: tcb.SYMBOL_CURRENT_ENV });
const db = app.database();

exports.main = async (event) => {
  const limit = event.limit ?? 50;
  const skip = event.skip ?? 0;

  const res = await db
    .collection('songs')
    .orderBy('releaseDate', 'desc')
    .skip(skip)
    .limit(limit)
    .get();

  return {
    data: res.data,
    total: res.data.length,
  };
};
