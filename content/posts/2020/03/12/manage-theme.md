---
title : "HugoのTheme(テーマ)を管理する方法"
date  : 2020-03-12T13:10:02+01:00
draft : false
tags  : [
    "hugo",
    "hugo-custom",
]
categories: [
    "サーバレスブログ"
]
meta_image  : "/thumbnails/2020-03-12-manage-theme.png"
description : ""
---

Hugoでは色々なテーマを簡単に利用することが可能です。配られたテーマをそのまま使う分には問題ないのですが、自分で何か変更したい場合、どのようにテーマを管理すれば良いかが迷います。

今回はどんなやり方があるのか、またその中からどれを選べば良いのかについて探っていきます。

# 管理の選択肢
1. Gitコマンドで管理: submodule
2. Gitコマンドで管理: subtree
3. テーマをダウンロードして管理

## 1. Gitコマンドで管理: submodule

「git submodule」はざっくり言うと誰かのリモートレポジトリを自分のローカルレポジトリから特定のコミットを「参照」するだけ。ちなみにHugoの[チュートリアル: Quickstart](https://gohugo.io/getting-started/quick-start/)ではこちらの方法が紹介されています。

{{< figure src="/images/2020/03-12-manage-theme-01-git-flow.png" >}}

参考にしたもの: [Git のさまざまなツール - サブモジュール](https://git-scm.com/book/ja/v2/Git-%E3%81%AE%E3%81%95%E3%81%BE%E3%81%96%E3%81%BE%E3%81%AA%E3%83%84%E3%83%BC%E3%83%AB-%E3%82%B5%E3%83%96%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%AB)

### メリット
- 自分でコードを管理する必要がない
- カスタマイズしなければアップデートが楽ちん

### デメリット
- カスタマイズすればするほどアップデートする際に元のレポジトリとコンフリクト(コードの差)が出始める

### 使い方例
#### テーマを追加する
```bash
$ git submodule add https://github.com/cntrump/hugo-notepadium.git themes/hugo-notepadium
$ tree -d -L 2
.
├── archetypes
├── content
│   └── posts
├── data
├── layouts
├── resources
│   └── _gen
├── static
│   ├── fonts
│   ├── images
│   └── thumbnails
└── themes
    ├── hugo-notepadium <-- これが追加される
```

#### テーマレポジトリを更新する
```bash
$ cd themes/hugo-notepadium
$ git submodule update --remote
```

特にカスタマイズをしていなければ、updateコマンドを実行してもエラーは出ません。ただあなたが手を加えたファイルがリモートレポジトリでも変更されていた場合、その差分を修正しない限りアップデートは行われません。

更にHugoで単にテーマを使う場合、リモートレポジトリを基本的に更新すること(git push)することは無いので、カスタマイズすればするほど最新版へのアップデートが複雑化していきます。

## 2. Gitコマンドで管理: subtree

「git subtree」はざっくり言うと誰かのリモートレポジトリを自分のローカルレポジトリに1つのコミットとして取り込みます。squash(複数のコミットを1つに省略できる)を忘れたまま取り込むとgitの履歴がとんでもないことになるので気をつけたいですね。

{{< figure src="/images/2020/03-12-manage-theme-02-git-subtree.png" >}}

参考にしたもの: [Git subtree: the alternative to Git submodule](https://www.atlassian.com/git/tutorials/git-subtree)

### メリット
- 完全にローカル環境で作業可能

### デメリット
- 管理が複雑で面倒になる

## 3. テーマをダウンロードして管理

これはgitを使わない超簡単なやり方です。

### メリット
- 初心者でも分かり易い
- カスタマイズが簡単

### デメリット
- アップデートするときに苦労する

### 使い方例

1. [hugo-notepadium](https://github.com/cntrump/hugo-notepadium)にアクセスします。
2. zipでダウンロードします。
{{< figure src="/images/2020/03-12-manage-theme-03-download.png" >}}
3. 解凍した際に作られるフォルダ「hugo-notepadium-master」を下記のように配置

```
$ tree -d -L 2
.
├── archetypes
├── content
│   └── posts
├── data
├── layouts
├── resources
│   └── _gen
├── static
│   ├── fonts
│   ├── images
│   └── thumbnails
└── themes
    ├── hugo-notepadium <-- themesフォルダを作り、hugo-notepadiumの名前に変えるだけ！
```

アップデートする際には、自分が変更したものを全て覚えておいて全て作り直すケースも出てきます。

# 結論
- Git初心者は「3. テーマをダウンロードして管理」で慣れるべき。
- Gitに慣れている人でHugo初心者の場合は「1. Gitコマンドで管理: submodule」から始めることをオススメします。
- カスタマイズ箇所が増えて、リモートレポジトリとコンフリクトする回数が多くなった場合は「2. Gitコマンドで管理: subtree」あるいは「3. テーマをダウンロードして管理」が良いのかも。

自分はしばらく「1. Gitコマンドで管理: submodule」で運用してみます。理由は自分の変更箇所が分かり易いから。(記事作成など、あとで何を変更したかを明確にするためでもあります。)
