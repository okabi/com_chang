# -*- coding: utf-8 -*-
require_relative './morpheme.rb'
require_relative './sqlite_util.rb'
require 'uri'

## マルコフ連鎖(三次)に関連するクラス
class Markov3
  ## 文章から新しいデータをストックする
  def store(text)
    text.gsub!(/@/, "＠")  # '@'は区切り文字なので
    arr = [@BEGIN] + @parser.analyze(text) + [@END]
    if arr.length == 2
      _store(arr[0], "", arr[1])
    else
      (arr.length - 2).times do |i|
        _store(arr[i], arr[i + 1], arr[i + 2])
      end
    end
  end


  ## ストックされたデータから新たな文章を生成する
  def create
    back = _random_word(@markov_begin_hash).split(/@/)
    result = ""
    while back[1] != @END
      result += back[1]
      key = back[0] + "@" + back[1]
      back = _random_word(@markov_hash[key]).split(/@/)
    end
    return result
  end


  ## 連鎖情報をインスタンスハッシュとDBに保存
  def _store(back_word, mid_word, forward_word)
    ## ヤバい文字を何とかする
    b = back_word.gsub("'", "''")
    m = mid_word.gsub("'", "''")
    f = forward_word.gsub("'", "''")
    
    ## ハッシュとDBの情報を更新
    key = back_word + "@" + mid_word
    chain = mid_word + "@" + forward_word
    if @markov_hash.include?(key)
      if @markov_hash[key].include?(chain)
        @markov_hash[key][chain] += 1
        where = "#{@DB_COLUMN_MORPHEME} = '#{b}@#{m}@#{f}'"
        @db.update([@DB_COLUMN_PROBABILITY], [@markov_hash[key][chain]], where)
      else
        @markov_hash[key].store(chain, 1)
        columns = [@DB_COLUMN_MORPHEME, @DB_COLUMN_PROBABILITY]
        values = ["'#{b}@#{m}@#{f}'", 1]
        @db.insert(columns, values)
      end
    else
      @markov_hash.store(key, {chain => 1})
      columns = [@DB_COLUMN_MORPHEME, @DB_COLUMN_PROBABILITY]
      values = ["'#{b}@#{m}@#{f}'", 1]
      @db.insert(columns, values)
    end
  end
  private :_store


  ## {word => probability}のハッシュからランダムに1単語を返す
  def _random_word(hash)
    ## ハッシュ内の全probabilityを合計する
    sum = 0
    hash.each do |key, value|
      sum += value
    end

    ## 乱数からwordを選択する
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
    @BEGIN = '__BEGIN__'  # 開始形態素
    @END = '__END__'      # 終了形態素
    @DB_COLUMN_MORPHEME = 'morpheme'       # DB上の連鎖情報列名  
    @DB_COLUMN_PROBABILITY = 'probability' # DB上の連鎖発生回数列名
    @parser = Morpheme.new                 # 形態素分割するすごいやつだよ
    @db = SqliteUtil.new(db_path, table_name)  # Sqliteのラッパーだよ
    markov_data = @db.select  # 連鎖情報をDBから取得

    ## 形態素が abc という文字列なら {"a@b" => {"b@c" => 1}} みたいな
    #  ハッシュにする。数字はその連鎖が出現した回数。
    @markov_hash = {}  # 連鎖情報
    @markov_begin_hash = {}  # 開始文字についての情報
    markov_data.each do |m|
      arr = m[1].split(/@/)
      key = arr[0] + "@" + arr[1]
      value = arr[1] + "@" + arr[2]
      if @markov_hash.include?(key)
        @markov_hash[key].store(value, m[2])
        @markov_begin_hash[key] += m[2]  if arr[0] == @BEGIN
      else
        @markov_hash.store(key, {value => m[2]})
        @markov_begin_hash.store(key, m[2])  if arr[0] == @BEGIN
      end
    end
  end
end
