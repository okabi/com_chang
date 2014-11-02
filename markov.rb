# -*- coding: utf-8 -*-
require_relative './morpheme.rb'
require_relative './sqlite_util.rb'
require 'uri'

## マルコフ連鎖に関連するクラス。
class Markov
  ## 文章から新しいデータをストックする
  def store(text)
    text.gsub!(/@/, "＠")
    arr = [@BEGIN] + @parser.analyze(text) + [@END]
    (arr.length - 1).times do |i|
      _store(arr[i], arr[i + 1])
    end
  end


  ## ストックされたデータから新たな文章を生成する
  def create
    back = @BEGIN
    result = ""
    while back != @END
      result += back if back != @BEGIN
      back = _random_word(@markov_hash[back])
    end
    return result
  end


  ## 連鎖情報をインスタンス変数とDBに保存
  def _store(back_word, forward_word)
    if @markov_hash.include?(back_word)
      if @markov_hash[back_word].include?(forward_word)
        @markov_hash[back_word][forward_word] += 1
        where = @DB_COLUMN_MORPHEME + " = '" + back_word + "@" + forward_word + "'"
        @db.update([@DB_COLUMN_PROBABILITY], [@markov_hash[back_word][forward_word]], where)
      else
        @markov_hash[back_word].store(forward_word, 1)
        columns = [@DB_COLUMN_MORPHEME, @DB_COLUMN_PROBABILITY]
        values = ["'" + back_word + "@" + forward_word + "'", 1]
        @db.insert(columns, values)
      end
    else
      @markov_hash.store(back_word, {forward_word => 1})
      columns = [@DB_COLUMN_MORPHEME, @DB_COLUMN_PROBABILITY]
      values = ["'" + back_word + "@" + forward_word + "'", 1]
      @db.insert(columns, values)
    end
  end
  private :_store


  ## {word => probability}のハッシュからランダムに1単語を返す
  def _random_word(hash)
    sum = 0
    hash.each do |key, value|
      sum += value
    end
    r = rand(sum)
    result = "__FAILED__"
    hash.each do |key, value|
      if r < value
        result = key
        break
      else
        r -= value
      end
    end
    return result
  end
  private :_random_word


  ## 形態素連鎖情報を格納しているDBとテーブル名を指定
  def initialize(db_path, table_name)
    @BEGIN = '__BEGIN__'
    @END = '__END__'
    @DB_COLUMN_MORPHEME = 'morpheme'
    @DB_COLUMN_PROBABILITY = 'probability'
    @parser = Morpheme.new
    @db = SqliteUtil.new(db_path, table_name)
    markov_data = @db.select
    @markov_hash = {}
    markov_data.each do |m|
      arr = m[1].split(/@/)
      if @markov_hash.include?(arr[0])
        @markov_hash[arr[0]].store(arr[1], m[2])
      else
        @markov_hash.store(arr[0], {arr[1] => m[2]})
      end
    end
  end
end
