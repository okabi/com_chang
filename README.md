# TwitterSimpleBot
## 概要
Ruby(1.9.3)とtwitter gem(5.11.0)を用いて簡単にTwitter Botが作れるようになったものだと思います。

## コード例
```rb
require 'twitter_simple_bot.rb'

config[:consumer_key] = "consumer_key"
config[:consumer_secret] = "consumer_secret"
config[:access_token] = "access_token"
config[:access_token_secret] = "access_token_secret"

client = TwitterSimpleBot.new(config)
client.tweet("Tweet with TwitterSimpleBot!")
```

## メソッド
### tweet
#### 引数
* `text`(String)…ツイートの本文内容。
* `options`…追加で情報が必要な場合、利用してください。
** `:reply_to_user`(String or Array(String))…リプライ対象のユーザID(name、@以降の英数字)。配列で渡すと複数の相手にリプライを送ることができます。
** `:reply_to_tweet`(Integer)…リプライ対象のツイートID。
** `:image`(String)…ツイートに含める画像のパス。