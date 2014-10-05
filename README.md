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
client.tweet("Tweet with TwitterSimpleBot!", :reply_to_user => "okabi13")
```

## メソッド
### コンストラクタ
##### 引数
以下の4つの引数は*どれか1つでも不備がある(渡されない)と例外が発生します*。
* `:consumer_key`(String)…Twitter Developersから取得できるConsumer Key。
* `:consumer_secret`(String)…Twitter Developersから取得できるConsumer Secret。
* `:access_token`(String)…Twitter Developersから取得できるAccess Token。
* `:access_token_secret`(String)…Twitter Developersから取得できるAccess Token Secret。

### `tweet`
##### 用途
1. Twitterにツイートを投稿します。
2. 指定ユーザにリプライを送ります。
3. 指定ツイートに対してリプライを送ります。
4. ローカルに保存した画像を付けたツイートを投稿します。
1〜4は並行して実行可能です。
##### 引数
* `text`(String)…ツイートの本文内容。
* `options`…追加で情報が必要な場合、利用してください。
 * `:reply_to_user`(String or Array(String))…リプライ対象のユーザID(name、@以降の英数字)。配列で渡すと複数の相手にリプライを送ることができます。
 * `:reply_to_tweet`(Integer)…リプライ対象のツイートID。
 * `:image`(String)…ツイートに含める画像のパス。
##### 戻り値
なし

### `timeline`
##### 用途
1. 自分のタイムラインを取得します。
2. 指定ユーザのタイムラインを取得します。
##### 引数
* `options`…追加で情報が必要な場合、利用してください。
 * `:id`(String)…指定ユーザのタイムラインを取得します。未指定の場合、認証ユーザのタイムラインを取得します。
 * `:count`(Integer)…取得するツイート数を指定します。デフォルトは20件です。最大200件だったと思います。
##### 戻り値
なし

### `follow`
##### 概要
1. 指定したユーザをフォローします。
2. フォローしていないフォロワーを全員フォロー(フォロー返し)します。
##### 引数
* `user`…フォローするユーザID。未指定の場合、フォローしていないフォロワーを全員フォロー(フォロー返し)します。
##### 戻り値
なし

### `unfollow`
##### 概要
1. 指定したユーザをアンフォロー(リムーブ)します。
2. フォローされていないフレンド(認証ユーザがフォローしている相手)を全員アンフォロー(リムーブ)します。
##### 引数
* `user`…アンフォローするユーザID。未指定の場合、フォローされていないフレンド(認証ユーザがフォローしている相手)を全員アンフォローします。
##### 戻り値
なし

### `user`
##### 概要
1. IDから、twitter gem の`Twitter::User`型ユーザ情報を返します。
##### 引数
* `id`…情報取得するユーザのID。未指定の場合、認証ユーザの情報を取得します。
##### 戻り値
指定ユーザの `Twitter::User` インスタンス。