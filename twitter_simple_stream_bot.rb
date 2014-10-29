# -*- coding: utf-8 -*-
require 'twitter'
require 'date'

class TwitterSimpleStreamBot
  ## ストリーミングの実行(無限ループ)
  def stream
    puts "Streamingを開始しました"
    begin
      @client.user do |status|
        case status
        when Twitter::Tweet
          if mention_me?(status) == true
            @on_catch_reply.call(status)
          else
            @on_catch_tweet.call(status)
          end
        when Twitter::DirectMessage
          @on_catch_DM.call(status)
        end
      end
    rescue => e
      @on_exception.call(e)
      retry
    end
  end


  ## エラーログを出す
  def error_log(text)
    File::open("./error_log/#{Date.today.to_s}.txt", "a") do |file|
      time = Time.now.strftime("%H:%M:%S")
      file.puts("#{time} #{text}")
    end
  end


  ## ツイートテキスト中に"@自分"が含まれるか
  def mention_me?(tweet)
    tweet.user_mentions.each do |u|
      return true if u.screen_name == @user_id
    end     
    return false
  end
  private :mention_me?


  ## キーとかいろいろ突っ込んでアカウントに接続する
  def initialize(options = {})
    options = {
      on_catch_tweet: lambda{|tweet|
        name = tweet.user.name
        sname = tweet.user.screen_name
        id = tweet.user.id
        text = tweet.text
        puts "@#{sname}(#{name})(#{id}): #{text}"
      },
      on_catch_reply: lambda{|tweet|
        name = tweet.user.name
        sname = tweet.user.screen_name
        id = tweet.user.id
        text = tweet.text
        puts "[reply @#{sname}(#{name})(#{id})]\n  #{text}"
      },
      on_catch_DM: lambda{|tweet|
        text = tweet.text
        puts "[DM]\n  #{text}"
      },
      on_exception: lambda{|exception|
        p exception.message
        error_log(exception.message)
      }
    }.merge(options)
    if options[:user_id] == nil
      raise ArgumentError, "please set options[:user_id]"
    end
    @user_id = options[:user_id]
    @on_catch_tweet = options[:on_catch_tweet]
    @on_catch_reply = options[:on_catch_reply]
    @on_catch_DM = options[:on_catch_DM]
    @on_exception = options[:on_exception]
    config = {}
    config[:consumer_key] = options[:consumer_key]
    config[:consumer_secret] = options[:consumer_secret]
    config[:access_token] = options[:access_token]
    config[:access_token_secret] = options[:access_token_secret]
    if config[:consumer_key] == nil
      raise ArgumentError, "please set options[:consumer_key]"
    elsif config[:consumer_secret] == nil
      raise ArgumentError, "please set options[:consumer_secret]"
    elsif config[:access_token] == nil
      raise ArgumentError, "please set options[:access_token]"
    elsif config[:access_token_secret] == nil
      raise ArgumentError, "please set options[:access_token_secret]"
    end
    @client = Twitter::Streaming::Client.new(config)
  end
end
