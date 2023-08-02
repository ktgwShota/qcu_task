# qcu_task

## 1. ローカルにリポジトリをcloneする
- 次のコマンドを実行 `git clone https://github.com/ktgwShota/qcu_task.git`

## 2. gemをインストール
- 次のコマンドを実行 `bundler install`

## 4. DBをインストール、テーブルを作成
- 次のコマンドを実行
```
brew install postgreSQL@14
brew services start postgresql@14
```

```
createdb qcu
psql qcu
CREATE TABLE task (
    id VARCHAR(255),
    title VARCHAR(255),        
    text TEXT
);
```

## 5. ローカル環境を立ち上げ、アクセスする
- 次のコマンドを実行 `ruby app.rb` 
- http://localhost:4567/ 

