# -*- coding: utf-8 -*-
require 'twitter'

class TwitterSimpleBot
  ## ツイートの投稿
  def tweet(text, options = {})
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


  ## フォローする。引数無指定はフォロー返しを行う。
  def follow(user = nil)
    if user != nil
      @client.follow(user)
    else
      follower_ids = @client.follower_ids
      friend_ids = @client.friend_ids
      follower_ids_array = _cursor_to_array(follower_ids)
      friend_ids_array = _cursor_to_array(friend_ids)
      unfollowing_follower_ids_array = follower_ids_array - friend_ids_array
      @client.follow(unfollowing_follower_ids_array)
    end
  end


  ## ユーザ情報(Twitter::User)の取得。ID指定可能。
  def user(id = nil)
    if id == nil
      return @client.user
    else
      return @client.user(id)
    end
  end


  ## Twitter::Cursor -> Array
  def _cursor_to_array(cursor)
    result = []
    cursor.each do |c|
      result += [c]
    end    
    return result
  end
  private :_cursor_to_array


  ## キーとかいろいろ突っ込んでアカウントに接続する
  def initialize(config = {})
    if config[:consumer_key] == nil
      raise ArgumentError, "please set config[:consumer_key]"
    elsif config[:consumer_secret] == nil
      raise ArgumentError, "please set config[:consumer_secret]"
    elsif config[:access_token] == nil
      raise ArgumentError, "please set config[:access_token]"
    elsif config[:access_token_secret] == nil
      raise ArgumentError, "please set config[:access_token_secret]"
    end
    @client = Twitter::REST::Client.new(config)
  end
end



load 'test.rb'


########################
# follow:フォロワーかつフレンドでない相手に無限にフォロリク送るので、
#        NGリスト内の相手には送らないようにすること。
# unfollow:作っておきたい。
########################
