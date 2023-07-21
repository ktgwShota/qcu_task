# frozen_string_literal: true

require 'date'
require 'sinatra'
require 'securerandom'
require 'yaml'

# CSS JS 画像などの使用に必要
set :public_folder, "#{File.dirname(__FILE__)}/public"

# セッション使用
enable :sessions

def load_data
  data_file = File.join(settings.root, 'form/data.yml')
  File.exist?(data_file) ? YAML.load_file(data_file) : {}
end

def save(data,type)
  File.open('form/data.yml', type) do |file|
    file.write(data.to_yaml.sub(/\A---\n/, '')) # 最初の`---`を削除して保存
  end
end

def esc(text) # エスケープ処理
  Rack::Utils.escape_html(text)
end

# トップページ
get '/' do
  erb :index, locals: { data: load_data }
end

# タスク追加ページ
get '/task' do
  erb :task
end

# タスク追加ページから送信されたデータを処理
post '/form' do
  task_data = {
    SecureRandom.uuid => {
      'title' => esc(params[:title]),
      'text' => esc(params[:text])
    }
  }
  save(task_data,'a')

  redirect '/'
end

# タスク詳細ページ
get '/task/:id' do
  task_id = params[:id]
  erb :task_detail, locals: { task_data: load_data[task_id], task_id: task_id }
end

# タスク詳細ページを編集するページ
get '/task/:id/edit' do
  erb :task_detail_edit, locals: { task_id: params['id'] }
end

# タスク詳細ページを編集する処理
patch '/task/:id/edit' do
  id = params[:id]
  data = load_data
  data[id]['title'] = esc(params[:title])
  data[id]['text'] = esc(params[:text])
  save(data,'a')

  redirect "/task/#{id}"
end

# タスクを削除　
delete '/task/:id' do
  task_id = params[:id]
  data = load_data
  data.delete(task_id)
  save(data,'w')

  redirect '/'
end
