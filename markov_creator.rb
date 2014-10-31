# -*- coding: utf-8 -*-
require_relative './morpheme.rb'
require 'uri'

## マルコフ連鎖に関連するクラス。文章群から作る場合。
class MarkovCreator
  ## 文章から新しいデータをストックする
  def store(text)
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


  ## 連鎖情報をインスタンス変数に保存
  def _store(back_word, forward_word)
    if @markov_hash.include?(back_word)
      if @markov_hash[back_word].include?(forward_word)
        @markov_hash[back_word][forward_word] += 1
      else
        @markov_hash[back_word].store(forward_word, 1)
      end
    else
      @markov_hash.store(back_word, {forward_word => 1})
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


  ## 形態素解析の準備
  def initialize()
    @BEGIN = '__BEGIN__'
    @END = '__END__'
    @parser = Morpheme.new
    @markov_hash = {}
  end
end
