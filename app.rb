# frozen_string_literal: true

require 'date'
require 'sinatra'
require 'securerandom'
require 'yaml'
require 'pg'

# CSS JS 画像などの使用に必要
set :public_folder, "#{File.dirname(__FILE__)}/public"

# セッション使用
enable :sessions

def conn
  PG.connect(
    host: 'localhost', # データベースのサーバーがあるホスト名 or IPアドレス
    dbname: 'qcu' # 接続するDB名
    # port: 5432, # ポート番号 何も指定しない場合はデフォルトの5432が指定される
    # 今回はDBアクセス時に認証を必要としていないので必要なし
    # user: 'u', # ユーザー名
    # password: 'p' # パスワード
  )
end

helpers do
  # エスケープ処理
  def esc(text)
    Rack::Utils.escape_html(text)
  end
end

# トップページ
get '/' do
  conn
  result = conn.exec('SELECT * FROM task')

  erb :index, locals: { data: result }
end

# タスク追加ページ
get '/task' do
  erb :task
end

# タスク追加ページから送信されたデータを処理
post '/form' do
  conn
  conn.exec_params(
    'INSERT INTO task (
      id,
      title,
      text
    )
    VALUES (
      $1,
      $2,
      $3
    )',
    [
      SecureRandom.uuid,
      params[:title],
      params[:text]

    ]
  )

  redirect '/'
end

# タスク詳細ページ
get '/task/:id' do
  task_id = params[:id]

  conn
  result = conn.exec('SELECT * FROM task WHERE id = $1', [task_id])
  html = []
  result.each do |row|
    html << "id: #{row['id']}"
    html << "title: #{row['title']}"
    html << "text: #{row['text']}"
  end

  erb :task_detail, locals: { task_id: task_id, task_data: html }
end

# タスク詳細ページを編集するページ
get '/task/:id/edit' do
  erb :task_detail_edit, locals: { task_id: params['id'] }
end

# タスク詳細ページを編集する処理
patch '/task/:id/edit' do
  id = params[:id]

  conn
  conn.exec_params(
    "UPDATE task
      SET title = $1,
          text = $2
      WHERE id = $3;",
    [params[:title], params[:text], id]
  )

  redirect "/task/#{id}"
end

# タスクを削除　
delete '/task/:id' do
  conn
  conn.exec_params('DELETE FROM task WHERE id = $1', [params[:id]])

  redirect '/'
end
