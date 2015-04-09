# -*- coding: utf-8 -*-
###########################################################
#  動作確認用。実際には使えないよ。
#  tweet201411_tbl とかから markov3d_tbl にアレする
###########################################################

require_relative './morpheme.rb'
require_relative './sqlite_util.rb'
require_relative './markov3.rb'
require 'pp'

## DBとかをあああああああああああする
DB = 'com_chang.db'
tweet_db = SqliteUtil.new(DB, 'tweet201412_tbl')
markov_db = SqliteUtil.new(DB, 'markov3d_tbl')
parser = Morpheme.new
markov_man = Markov3.new(DB, 'markov3d_tbl')  # マルコフマンはマルコフ連鎖する

## ツイートデータをがががあっがあする
## 役目を終えたので就寝
# tweet_data = tweet_db.select
# tweet_data.each do |t|
#   markov_man.store(t[2])
# end

## とりあえず30文くらい出してみる
(1..30).each do |i|
  pp markov_man.create
end 
