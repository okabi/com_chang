# -*- coding: utf-8 -*-
## ruby-sqlite3を使用。
require 'sqlite3'

## RubyからSQLITEを扱う。
class SqliteUtil
  ## テーブル情報を返す
  def select(options = {})
    sql = "SELECT "
    if options[:columns] == nil
      sql += "*"
    else
      options[:columns].each do |c|
        sql += "#{c},"
      end
      sql.chop!
    end
    sql += " FROM #{@table_name}"
    sql += " WHERE #{options[:where]}" if options[:where] != nil
    return sql_exec(sql)
  end

  
  ## テーブルに情報を挿入する
  def insert(columns, values)
    sql = "INSERT INTO #{@table_name} ("
    columns.each do |c|
      sql += "#{c},"
    end
    sql.chop!
    sql += ") VALUES("
    values.each do |v|
      sql += "#{v},"      
    end
    sql.chop!
    sql += ")"
    return sql_exec(sql)
  end


  ## テーブルの情報を更新する
  def update(columns, values, where = nil)
    sql = "UPDATE #{@table_name} SET "
    columns.length.times do |i|
      sql += "#{columns[i]} = #{values[i]},"
    end
    sql.chop!
    sql += " WHERE #{where}" if where != nil
    return sql_exec(sql)
  end


  ## テーブルの情報を削除する
  def delete(where)
    sql = "DELETE FROM #{@table_name} WHERE #{where}"
    return sql_exec(sql)
  end


  ## SQL文の実行
  def sql_exec(sql)
    return @db.execute(sql)
  end
  private :sql_exec


  ## オープンするDBのパスを指定する
  def initialize(dbpath, table_name)
    @db = SQLite3::Database.new(dbpath)
    @table_name = table_name
  end 
end
