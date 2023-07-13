# require 'active_record'
require 'sinatra'
# require 'sinatra/reloader'
require 'logger'
require 'yaml'
require 'securerandom'
require 'date'

# ベーシック認証のユーザー名とパスワード
USERNAME = 'qcu'
PASSWORD = '%9mvL*@G*bv9Z^'

# ベーシック認証を確認するメソッド
def protected!
  unless authorized?
    response['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "パスワード認証してクレオパトラ（リロードすれば再度認証画面が出てきます）"
  end
end

# ユーザー名とパスワードを確認するメソッド
def authorized?
  @auth ||= Rack::Auth::Basic::Request.new(request.env)
  @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [USERNAME, PASSWORD]
end

# ルートへのアクセスを保護
before do
  protected!
end

# 静的ファイルの提供設定
set :public_folder, File.dirname(__FILE__) + '/public'

# セッションを使用
enable :sessions

# トップページ
get '/' do
  # 保存されたデータを読み込み
  data_file = File.join(settings.root, 'form/data.yml')
  data = File.exist?(data_file) ? YAML.load_file(data_file) : {}
  
  # クエリパラメータがあった場合は取得する
  if params[:user]
    user_number = params[:user].to_i
  end
  if params[:fixed]
    fixed_number = params[:fixed].to_i
  end

  def main_box_content(data)
    html = ''
    data.each do |key, value|
      html += <<~HTML
        <div class="content">
          <a href="/task/#{key}">
            <div>#{value['title']}</div>
            <div>#{value['text']}</div>
            <div>#{value['start']} 〜 #{value['fixed']}</div>
            <div>#{value['section']}</div>
            <div class="status">#{value['status']}</div>
            <div>工数：#{value['cost']}</div>
          </a>
        </div>
      HTML
    end
    return html
  end

  # ユーザーを絞り込み
  def user_filter(data, name)
    data.select { |key, value| value["name"] == name } 
  end

  # 期日でソート
  def sort_fixed(data)
    data.sort_by { |_, value| value["fixed"] }.reverse
  end

  # 本日期日のタスクを取得
  def get_today_fixed_tasks(data)
    data.select { |key, value| value["fixed"] == Date.today.to_s }
  end
  
  # 今週期日のタスクを取得
  def get_week_fixed_tasks(data)
    today = Date.today
    start_week = today - today.wday
    end_week = start_week + 6
    # 今週の日付全て
    week = (start_week..end_week).map(&:to_s)

    data.select { |key, value| week.include?(value["fixed"]) }
  end

  # 全工数の合算を取得
  def get_costs(data)
    task = data.select { |key, value| value.has_key?("cost") }
    if task.empty?
      return 0
    else
      task.values.map { |value| value["cost"].to_i }.sum
    end
  end

  # index.erbに変数を渡す
  erb :index, locals: { user_number: user_number, fixed_number: fixed_number, data: data }

end

# タスク追加ページ
get '/task' do
  erb :task
end

# タスク追加ページから送信されたデータを処理
post '/form' do 
  # 送信されたデータを変数に格納
  name = params[:name]
  title = params[:title]
  text = params[:text]
  start = params[:start]
  fixed = params[:fixed]
  section = params[:section]
  notion = params[:notion]
  slack = params[:slack]
  status = params[:status]
  progress = params[:progress]
  cost = params[:cost]

  # 変数をYAML形式でファイルに保存
  data_file = "form/data.yml"
  file = File.open("form/data.yml", "a")
  file.write(SecureRandom.uuid  + ":\n" ) # タスクID
  file.write("  name: #{name}\n") # 担当者
  file.write("  title: #{title}\n") # タイトル
  file.write("  text: #{text}\n") # 本文
  file.write("  start: '#{start}'\n") # 開始日
  file.write("  fixed: '#{fixed}'\n") # 期日
  file.write("  section: #{section}\n") # セクション
  file.write("  notion: #{notion}\n") # notionリンク
  file.write("  slack: #{slack}\n") # slackリンク
  file.write("  status: #{status}\n") # slackリンク
  file.write("  progress: #{progress}\n") # slackリンク
  file.write("  cost: #{cost}\n") # slackリンク
  file.close

  redirect '/'
end


# タスク詳細ページ
get '/task/:id' do
  task_id = params[:id]
  data_file = File.join(settings.root, 'form/data.yml')
  data = File.exist?(data_file) ? YAML.load_file(data_file) : {}
  task_data = data[task_id]
  erb :task_detail, locals: { task: task_data, task_id: task_id }
end

# タスク詳細ページを編集
patch '/task/:id' do
  id = params[:id]
  name = params[:name]
  title = params[:title]
  text = params[:text]
  start = params[:start]
  fixed = params[:fixed]
  section = params[:section]
  notion = params[:notion]
  slack = params[:slack]
  status = params[:status]
  progress = params[:progress]
  cost = params[:cost]

  # YAMLファイルを読み込み
  data = YAML.load_file("form/data.yml")

  # ハッシュの値を編集
  data[id]['name'] = name
  data[id]['title'] = title
  data[id]['text'] = text
  data[id]['start'] = start
  data[id]['fixed'] = fixed
  data[id]['section'] = section
  data[id]['notion'] = notion
  data[id]['slack'] = slack
  data[id]['status'] = status
  data[id]['progress'] = progress
  data[id]['cost'] = cost

  # YAMLファイルに反映
  File.open("form/data.yml", 'w') do |file|
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

  redirect "/"
end



