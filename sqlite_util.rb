# -*- coding: utf-8 -*-
## ruby-sqlite3を使用。
require 'sqlite3'

## RubyからSQLITEを扱う。
class SqliteUtil
  ## テーブル情報を返す
  ## 例. select(hoge_tbl, :columns => name, :where => "id > 5 AND id < 10"])
  def select(table_name, options = {})
    sql = "SELECT "
    if options[:columns] == nil
      sql += "*"
    elsif options[:columns].is_a?(String)
      sql += options[:columns]
    else
      options[:columns].each do |c|
        sql += c + ","
      end
      sql.chop!
    end
    sql += " FROM " + table_name
    sql += " WHERE " + options[:where] if options[:where] != nil
    return sql_exec(sql)
  end

  
  def insert(table_name, options = {})
  end


  ## SQL文の実行
  def sql_exec(sql)
    return @db.execute(sql)
  end
  private :sql_exec


  ## オープンするDBのパスを指定する
  def initialize(dbpath)
    @db = SQLite3::Database.new(dbpath)
  end 
end


su = SqliteUtil.new('./com_chang.db')
p su.select('markov_tbl', :columns => 'id', :where => 'probability = 1')
