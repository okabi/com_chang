# -*- coding: utf-8 -*-
require 'twitter'

class TwitterSimpleBot
  ## ツイートの投稿
  def tweet(text, options={})
    options = {
      reply_to_tweet: nil,  # リプライ対象のツイートID
      reply_to_user: nil,   # リプライ対象のユーザID(screen_name)(配列可)
      image: nil            # アップロードする画像のパス
    }.merge(options)
    ## @の追加
    if options[:reply_to_user] != nil
      if options[:reply_to_user].is_a?(String)
        text = "@" + options[:reply_to_user] + " " + text
      elsif options[:reply_to_user].is_a?(Array)
        options[:reply_to_user].each do |r|
          text = "@" + r + " " + text
        end
      end
    end
    ## ツイート処理
    if options[:image] != nil
      @client.update_with_media(text, File.new(options[:image]), :in_reply_to_status_id => options[:reply_to_tweet])
    else
      @client.update(text, :in_reply_to_status_id => options[:reply_to_tweet])
    end
  end

  
  ## ユーザ情報の取得。ID指定可能。
  def user(id=nil)
    if id == nil
      return @client.user
    else
      return @client.user(id)
    end
  end
  

  ## タイムラインを取得。ID指定等可能。
  def timeline(options)
    options = {
      id: nil,
      count: 20
    }.merge(options)
    if options[:id] == nil
      return @client.user_timeline(@client.user, :count => options[:count])
    else
      return @client.user_timeline(options[:id], :count => options[:count])
    end
  end


  ## キーとかいろいろ突っ込んでアカウントに接続する
  def initialize(config = {})
    config = {
      consumer_key: "default",
      consumer_secret: "default",
      access_token: "default",
      access_token_secret: "default",      
    }.merge(config)
    # 引数をチェックし、セットされていないものがあれば例外発生
    if config[:consumer_key] == "default"
      raise ArgumentError, "please set config[:consumer_key]"
    elsif config[:consumer_secret] == "default"
      raise ArgumentError, "please set config[:consumer_secret]"
    elsif config[:access_token] == "default"
      raise ArgumentError, "please set config[:access_token]"
    elsif config[:access_token_secret] == "default"
      raise ArgumentError, "please set config[:access_token_secret]"
    end
    # Twitterとのインタフェース作成
    @client = Twitter::REST::Client.new(config)
  end
end


load "test.rb"
