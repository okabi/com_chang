# -*- coding: utf-8 -*-
require_relative './twitter_simple_bot.rb'
require_relative './twitter_simple_stream_bot.rb'
require_relative './markov.rb'
require_relative './sqlite_util.rb'

## リプライに反応するようにしよう
## あとはスマホのメモ帳に

## コンちゃん本体
class ComChang
  ## Streamingの実行
  def run
    @stream.stream
  end


  ## tweetを受け取って、形態素に分割してDBに保存する
  def save_tweet(tweet, message)
    name = tweet.user.name
    sname = tweet.user.screen_name
    id = tweet.user.id
    text = tweet.text.to_s
    puts "@#{sname}(#{name})(#{id}): #{text}"
    if should_save?(tweet) == true
      text = validate(text)
      puts "  [#{message}]保存 -> #{text}"
      @markov.store(text)
      @db.insert(["user", "tweet"], ["\"#{id}\"", "\"#{text}\""])
    end
  end


  ## tweet本文から保存対象外の文字列を省いて返す
  def validate(text)
    # @hogeは消す
    text = text.gsub(/@(\w)+/, "")
    # URLは消す
    text = text.gsub(/http(s)?:\/\/[\w.\/]+/, "")
    # &とかの文字を元に戻す
    text = CGI.unescapeHTML(text)
    return text
  end


  ## 保存すべきtweetの場合はtrueを返す
  def should_save?(tweet)
    name = tweet.user.name.to_s
    sname = tweet.user.screen_name.to_s
    id = tweet.user.id
    text = tweet.text.to_s
    # "RT "から始まる場合はダメ
    return false if text =~ /^RT /
    # 自分のツイートは保存対象から外す
    return false if sname == "lunatic_club"
    # nameかscreen_nameに"bot","BOT","Bot"が含まれる場合は保存対象から外す
    return false if sname =~ /([Bb]ot)|(BOT)/
    return true
  end


  ## 2次マルコフ連鎖でツイートする
  def tweet_markov
    @client.tweet(@markov.create)
  end


  ## 任意テキストをツイートする
  def tweet(text)
    @client.tweet(text)
  end


  ## コンちゃんの初期化
  def initialize(consumer_key, consumer_secret, access_token, access_token_secret, user_id, db_path)
    # 設定に必要なデータの準備
    config_rest = {}
    config_rest[:consumer_key] = consumer_key
    config_rest[:consumer_secret] = consumer_secret
    config_rest[:access_token] = access_token
    config_rest[:access_token_secret] = access_token_secret
    config = {}
    config[:consumer_key] = consumer_key
    config[:consumer_secret] = consumer_secret
    config[:access_token] = access_token
    config[:access_token_secret] = access_token_secret
    config[:user_id] = user_id
    
    # マルコフ連鎖・およびSQLite操作インスタンスの宣言
    @markov = Markov.new(db_path, 'markov_tbl')
    @db = SqliteUtil.new(db_path, 'tweet_tbl')

    # StreamingでTweetを受け取った時の処理
    config[:on_catch_tweet] = lambda{|tweet|
      save_tweet(tweet, "tweet")
    }

    # StreamingでReplyを受け取った時の処理
    config[:on_catch_reply] = lambda{|tweet|
      save_tweet(tweet, "reply")
    }

    # Streamingで例外を受け取った時の処理
    config[:on_exception] = lambda{|exception|
      p exception.message
      @stream.error_log(exception.message)
      begin
        tweet("@okabi13 エラー発生した〜〜〜")
      rescue
      end
    }
    
    # 初期化〜〜〜〜〜〜
    @user_id = user_id
    @stream = TwitterSimpleStreamBot.new(config)
    @client = TwitterSimpleBot.new(config_rest)
  end
end
