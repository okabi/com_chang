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


  ## tweetを受け取って、形態素に分割して適切なDBに保存する。
  #  反応ワードが含まれる場合、IDnumを返す。含まれない場合、nilを返す。
  def save_tweet(tweet, message)
    name = tweet.user.name
    sname = tweet.user.screen_name
    id = tweet.user.id
    text = tweet.text.to_s
    puts "@#{sname}(#{name})(#{id}): #{text}"
    if should_save?(tweet) == true
      text = validate(text)
      puts "  [#{message}]保存 -> #{text}"
      store_tweet(tweet)
      type = tweet_type(text)
      if type == nil
        @markov0.store(text)
        @markov1.store(text)
      else
        puts "========================= #{@REG[type][0]} ========================="
        @special_word_markov[type].store(text) if @REG[type][1] =~ /markov/
        @client.favorite(tweet.id) if @REG[type][1] =~ /fav/        
        return type
      end
    end
    return nil
  end


  ## DBにツイート情報(Full)を保存する
  def store_tweet(tweet)
    begin
      date = Date.today.strftime("%Y%m")
      if @tweet_tbl != "tweet#{date}_tbl"
        @tweet_tbl = "tweet#{date}_tbl"              
        @db = SqliteUtil.new(@db_path, @tweet_tbl)
      end
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


  ## コマンドなら0以外を返す
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


  ## 反応ワードに応じた、ツイートすべき文を返す。
  #  typeは@REGのIDnum。すなわち反応ワード。nilなら普通のマルコフ連鎖。
  def create_special_text(type = nil)
    if type == nil
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
        return @markov0.create
      else
        return @markov1.create
      end
    else
      if @REG[type][1] =~ /markov/
        return @special_word_markov[type].create
      elsif @REG[type][1] =~ /ohchinchin/
        return "チン・チン"
      end
    end
  end


  ## ツイートに対してリプライする。
  #  最近3分間に5回以上リプライを返した相手には返さない。
  #  typeは@REGのIDnum。すなわち反応ワード。nilなら普通にツイートする。
  def reply(tweet, type = nil)
    sname = tweet.user.screen_name
    should_reply = true
    now = Time.now.to_i
    if @reply_history.has_key?(sname) == false
      @reply_history[sname] = [now]
    else
      if @reply_history[sname].length == 5
        if now - @reply_history[sname][0] <= 3 * 60
          should_reply = false
        else
          3.times do |i|
            @reply_history[sname][i] = @reply_history[sname][i + 1]
          end
          @reply_history[sname].delete_at(-1)
          @reply_history[sname].push(now)
        end
      else
        @reply_history[sname].push(now)
      end
    end
    if should_reply == true
      if type == nil
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
      else
        begin        
          @client.tweet(create_special_text(type), :reply_to_user => tweet.user.screen_name, :reply_to_tweet => tweet.id)
        rescue
          retry
        end      
      end
    end
  end


  ## 反応ワードが含まれるツイートの場合、IDnumを返す。
  #  返すIDは、IDの小さいものが優先
  #  反応ワードが含まれない場合、nilを返す。
  def tweet_type(text)
    @REG.length.times do |i|
      if text =~ @REG[i][2]
        return i
      end
    end
    return nil
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


  ## 2次マルコフ連鎖でツイートする。
  #  typeは@REGのIDnum。すなわち反応ワード。nilなら普通にツイートする。
  def tweet_markov(type = nil)
    @client.tweet(create_special_text(type))
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

    # 反応ワードの準備
    @REG = [["chinko", "markov|fav", Regexp.new("ちんこ|ちんぽ|チンコ|チンポ|(ち|チ)[ー〜]*(ん|ン)(・)*(ち|チ)[ー〜]*(ん|ン)|chin[- 　]*chin")],
            ["ohchinchin", "ohchinchin|tl", Regexp.new("(oh|Oh|OH|[おぉオォｵｫ][おぉオォｵｫうぅウゥｳｩー〜~]+)(・|\\.|…|。|、|！|!|？|\\?|ー|〜|~)*$")],
            ["ohayou", "markov|tl", Regexp.new("おはよ")],
            ["oyasumi", "markov|tl", Regexp.new("おやすみ|親炭")],
            ["com_chang", "fav", Regexp.new("コン(ちゃん|さん)")]
           ]
    
    # マルコフ連鎖・およびSQLite操作インスタンスの宣言
    @db_path = db_path
    @markov0 = Markov.new(@db_path, 'markov0_tbl')
    @markov1 = Markov.new(@db_path, 'markov1_tbl')
    date = Date.today.strftime("%Y%m")
    @tweet_tbl = "tweet#{date}_tbl"
    @db = SqliteUtil.new(@db_path, @tweet_tbl)
    @special_word_markov = []
    @REG.length.times do |i|
      if @REG[i][1] =~ /markov/
        @special_word_markov.push(Markov.new(@db_path, "#{@REG[i][0]}_tbl"))
      else 
        @special_word_markov.push(nil)
      end
    end

    # StreamingでTweetを受け取った時の処理
    config[:on_catch_tweet] = lambda{|tweet|
      type = save_tweet(tweet, "tweet")
      if type != nil
        if @REG[type][1] =~ /tl/
          reply(tweet, type)
        end
      end
    }

    # StreamingでReplyを受け取った時の処理
    config[:on_catch_reply] = lambda{|tweet|
      message = command(tweet)
      if message == 0 && should_reply?(tweet) == true
        type = save_tweet(tweet, "reply")
        if type != nil && !(@REG[type][1] =~ /markov/ || @REG[type][1] =~ /ohchinchin/)
          type = nil
        end
        reply(tweet, type)
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
    # ↓key:screen_name, value:リプライ送信時間(int)の配列
    @reply_history = {}
    @stream = TwitterSimpleStreamBot.new(config)
    @client = TwitterSimpleBot.new(config_rest)
    @user_num = @client.user.id
  end
end
