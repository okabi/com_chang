# -*- coding: utf-8 -*-
## mecab-rubyを使用。
require 'MeCab'

## 形態素解析クラス。とりあえず文字列を形態素に分解するだけ。
class Morpheme
  ## 与えられた文字列を形態素に分解する
  def analysis(text)
    n = @parser.parseToNode(text)
    result = []
    while n
      str = n.surface.to_s
      result.push(str) if !(str.empty?)
      n = n.next
    end
    return result
  end


  ## コンストラクタ
  def initialize
    @parser = MeCab::Tagger.new
  end
end
