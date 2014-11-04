# -*- coding: utf-8 -*-
require 'date'
require_relative './twitter_simple_bot.rb'
require_relative './twitter_simple_stream_bot.rb'
require_relative './markov.rb'
require_relative './markov_creator.rb'
require_relative './sqlite_util.rb'

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
      @markov0.store(text)
      @markov1.store(text)
      store_tweet(tweet)
    end
  end


  ## DBにツイート情報を保存する
  def store_tweet(tweet)
    begin
      text = tweet.text.to_s.gsub("'", "''")
      @db.insert(["user", "tweet"], ["'#{tweet.user.id}'", "'#{text}'"])
    rescue
      date = Date.today.strftime("%Y%m")
      @tweet_tbl = "tweet#{date}_tbl"
      @db.create(@tweet_tbl, 
                 ['id', 'user', 'tweet'],
                 ['INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL', 'TEXT NOT NULL', 'TEXT NOT NULL'])
      @db = SqliteUtil.new(@db_path, @tweet_tbl)
      retry
    end
  end


  ## tweet本文から保存対象外の文字列を省いて返す
  def validate(text)
    # 先頭のRT は消す
    text = text.gsub(/^RT /, "")
    # @hogeは消す
    text = text.gsub(/@(\w)+/, "")
    # URLは消す
    text = text.gsub(/http(s)?:\/\/[\w.\/]+/, "")
    # &とかの文字を元に戻す
    text = CGI.unescapeHTML(text)
    return text
  end


  ## コマンドならそれに従う
  def command(tweet)
    sname = tweet.user.screen_name.to_s
    text = tweet.text.to_s
    if sname == "okabi13" || sname == "abiko131"
      time = Time.now.strftime("%H:%M:%S")
      if text =~ /kill/
        @client.tweet("ぐはっ #{time}")
        return 1
      elsif text =~ /ping/
        @client.tweet("@#{sname} pong #{time}")
        return 2
      end
    end
    return 0
  end


  ## ツイートに対してリプライする
  def reply(tweet)
    mc = MarkovCreator.new
    tweets = @client.timeline(:id => tweet.user.id, :count => 200)
    tweets.each do |t|
      mc.store(validate(t.text))
    end
    begin
      @client.tweet(mc.create, :reply_to_user => tweet.user.screen_name, :reply_to_tweet => tweet.id)
    rescue
      retry
    end
  end


  ## 保存すべきtweetの場合はtrueを返す
  def should_save?(tweet)
    name = tweet.user.name.to_s
    sname = tweet.user.screen_name.to_s
    text = tweet.text.to_s
    # "RT "から始まる場合はダメ
    return false if text =~ /^RT /
    # 自分のツイートは保存対象から外す
    return false if sname == @user_id
    # nameかscreen_nameに"bot","BOT","Bot"が含まれる場合は保存対象から外す
    return false if sname =~ /([Bb]ot)|(BOT)/
    return false if name =~ /([Bb]ot)|(BOT)/
    return true
  end


  ## リプライを返すべきtweetの場合はtrueを返す
  def should_reply?(tweet)
    sname = tweet.user.screen_name.to_s
    text = tweet.text.to_s
    # "RT "から始まる場合はスルー
    return false if text =~ /^RT /
    # 自分のリプライは返信対象から外す(そもそもリプライ飛ばさないけど…)
    return false if sname == @user_id
    return true
  end


  ## 2次マルコフ連鎖でツイートする
  def tweet_markov
    yesterday = Time.now.to_i - (24 * 3600)
    y_index = (yesterday % 14) / 7
    today = Time.now.to_i / (24 * 3600)
    tbl_index = (today % 14) / 7
    if y_index != tbl_index
      if y_index == 0
        @markov0.delete
      else
        @markov1.delete
      end
    end
    if tbl_index == 0
      @client.tweet(@markov0.create)
    else
      @client.tweet(@markov1.create)
    end
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
    @db_path = db_path
    @markov0 = Markov.new(@db_path, 'markov0_tbl')
    @markov1 = Markov.new(@db_path, 'markov1_tbl')
    date = Date.today.strftime("%Y%m")
    @tweet_tbl = "tweet#{date}_tbl"
    @db = SqliteUtil.new(@db_path, @tweet_tbl)

    # StreamingでTweetを受け取った時の処理
    config[:on_catch_tweet] = lambda{|tweet|
      save_tweet(tweet, "tweet")
    }

    # StreamingでReplyを受け取った時の処理
    config[:on_catch_reply] = lambda{|tweet|
      message = command(tweet)
      if message == 0 && should_reply?(tweet) == true
        save_tweet(tweet, "reply")
        reply(tweet)
      elsif message == 1
        File::open("./state.txt", "w") do |file|
          file.puts("DEAD")
        end
        exit
      end
    }

    # StreamingでFollowを受け取った時の処理
    config[:on_catch_follow] = lambda{|event|
      if event.source.id == @user_num
        puts "[follow] フォローを返しました。"
      else
        puts "[follow] フォローを受け取りました。"
        @client.follow(event.source)
      end
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
    @user_num = @client.user.id
  end
end
