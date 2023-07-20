# frozen_string_literal: true

require 'date'
require 'sinatra'
require 'securerandom'
require 'yaml'

# CSS JS 画像などの使用に必要
set :public_folder, "#{File.dirname(__FILE__)}/public"

# セッション使用
enable :sessions

# トップページ
get '/' do
  data_file = File.join(settings.root, 'form/data.yml')
  data = File.exist?(data_file) ? YAML.load_file(data_file) : {}

  def main_box_content(data)
    html = ''
    data.each do |key, value|
      html += <<~HTML
        <div class="content">
          <a href="/task/#{key}"><div>#{value['title']}</div><div>#{value['text']}</div></a>
        </div>
      HTML
    end
    html
  end

  erb :index, locals: { data: data }
end

# タスク追加ページ
get '/task' do
  erb :task
end

# タスク追加ページから送信されたデータを処理
post '/form' do
  file = File.open('form/data.yml', 'a')
  file.write("#{SecureRandom.uuid}:\n")
  file.write("  title: #{params[:title]}\n")
  file.write("  text: #{params[:text]}\n")
  file.close

  redirect '/'
end

# タスク詳細ページ
get '/task/:id' do
  task_id = params[:id]
  data_file = File.join(settings.root, 'form/data.yml')
  data = File.exist?(data_file) ? YAML.load_file(data_file) : {}
  erb :task_detail, locals: { task_data: data[task_id], task_id: task_id }
end

# タスク詳細ページを編集するページ
get '/task/:id/edit' do
  erb :task_detail_edit, locals: { task_id: params['id'] }
end

# タスク詳細ページを編集する処理
patch '/task/:id/edit' do
  id = params[:id]
  data = YAML.load_file('form/data.yml')
  data[id]['title'] = params[:title]
  data[id]['text'] = params[:text]
  File.open('form/data.yml', 'w') do |file|
    file.write(data.to_yaml)
  end

  redirect "/task/#{id}"
end

# タスクを削除　
delete '/task/:id' do
  task_id = params[:id]
  data_file = File.join(settings.root, 'form/data.yml')
  data = File.exist?(data_file) ? YAML.load_file(data_file) : {}
  data.delete(task_id)
  File.open(data_file, 'w') { |f| f.write(data.to_yaml) }

  redirect '/'
end
