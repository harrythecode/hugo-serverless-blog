---
title : "Jenkinsのベストプラクティスについて調べてみた"
date  : 2020-06-03T12:36:16Z
draft : false
tags  : [
    "jenkins",
]
categories: [
    "DevOps",
    "CI/CD"
]
meta_image  : "/thumbnails/2020-06-03-jenkins.png"
description : ""
---

DevOpsの活動に欠かせないCI/CDツール。世の中にはたくさんの種類があります。例えば以下のようなものが現在流行っています。

* Jenkins
* Circle CI
* Github Actions
* AWS Pipeline
* etc...

まだまだ探せばあると思いますが今回は「Jenkins」のCI/CDを設計する上でどのようなことに気をつけるべきかを調べます。

# 検索してみる
検索キーワードは自分は以下の通り使い分けています。

### 概念を理解する時
```
"検索ワード" tutorial
```

### 使い方のオススメを調べる時
```
"検索ワード" best practices
```

### 実例を理解する時
```
"検索ワード" qiita
"検索ワード" example
"検索ワード" doc
```

## 「jenkins best practices」で検索

こちらのサイトが良くまとまっていました。

* [Top 10 Best Practices for Jenkins Pipeline](https://dzone.com/articles/top-10-best-practices-for-jenkins-pipeline)
```
1. Do: Use the Real Jenkins Pipeline
2. Do: Develop Your Pipeline As Code
3. Do: All Work Within a Stage
4. Do: All Material Work Within a Node
5. Do: Work You Can Within a Parallel Step
6. Do: Acquire Nodes Within Parallel Steps
7. Don’t: Use Input Within a Node Block
8. Do: Wrap Your Inputs in a Timeout
9. Don’t: Set Environment Variables With the env Global Variable
10. Do: Prefer Stashing Files to Archiving Them
```

以下は上記の一言まとめです。

### 1. DO: 最新版を使う
古いプラグインは使わない。

### 2. DO: パイプラインをコード化する
GithubやBitBucketなどのコードレポジトリと連携して必ずパイプラインをコード化しましょう。手動で設定するのは「DevOps」の道からかけ離れて行く古いやり方です。

### 3. DO: ステージごとに分ける
「build, test, deploy」のように各ステージに分けてコードを書くと後で視覚的に見ることができます。

```yml
stage 'build'
//build
stage 'test'
//test
```

### 4. DO: 環境整備はnode内で行う
環境整備、例えば「Gitサーバからコードをクーロンする、Javaアプリをコンパイルする」などの処理は全て「`node`」エージェント内で済ませましょう。

```yml
stage 'build'
node{
    checkout scm
    sh 'mvn clean install'
}
```

### 5. DO: パイプラインの並列処理をする
Jenkinsはあなたのパイプラインを並列処理することができます。並列処理することで開発スピードが格段に上がります。

### 6. DO: 環境整備(node)の並列処理をする
4 & 5の組み合わせです。

```yml
parallel 'integration-tests':{
    node('mvn-3.3'){ ... }
}, 'functional-tests':{
    node('selenium'){ ... }
}
```

### 7. DON'T: ユーザ入力要求はnode内で行わない
inputステートメントは自動または手動のいずれにしろ、時間を取ります。node内ではJenkins内で負荷が高い処理のため、そこにユーザ入力要求を入れ込むのはパフォーマンス低下につながるので絶対に辞めましょう。

```yml
stage 'deployment'
input 'Do you approve deployment?'
node{
    //deploy the things
}
```

### 8. DO: inputはタイムアウトをつける
パイプラインをきれいに保つためにinputがなかった場合の時も考えることがベストプラクティスです。

```yml
timeout(time:5, unit:'DAYS') {
    input message:'Approve deployment?', submitter: 'it-ops'
}
```

### 9. DON'T: envグローバル変数を用いて環境変数を設定しない
env変数はグローバルであり、環境をグローバルに変更するため、直接変更することは推奨されません。なので「`withEnv`」を使いましょう。

```yml
withEnv(["PATH+MAVEN=${tool 'm3'}/bin"]) {
    sh "mvn clean verify"
}
```

### 10. DO: archiveの代わりにstash/unstashを使う
stash機能が実装される前はarchiveが「node, stage」間でファイルをやり取りするベストプラクティスでした。今は「stash/unstash」を使うことを推奨しています。(archiveは元々長期的なストレージの役割を目的としています。)


```yml
stash excludes: 'target/', name: 'source'
unstash 'source'
```

## ちなみに「jenkins ベストプラクティス」でも検索
* [Jenkins Pipeline の11個のベスト・プラクティス - Qiita](https://qiita.com/AHA_oretama/items/16d61d0af566ee7bf77c)
    * 僕が見つけた英語サイトの翻訳ですね。
* [Jenkins 再入門](https://www.slideshare.net/miyajan/jenkins-61133952)
    * 情報自体は2016年と古いが何が運用を妨げるのかを理解することが可能。

# 最後に
自分なりに調べましたがJenkinsはできることの自由さゆえ、様々な使われ方をされるようです。ベストプラクティスに沿わない使い方をするとチーム全体で運用するという条件の場合、かなりカオスな状況になることが容易に推測されます。

何かを実装する前にこういった知識を事前に仕入れておくことで、自分がゼロから構築する際の手助けとなります。

DevOpsエンジニアとして学ぶことは幅広く、こういった良く使われる手法を効率良く学ぶことがDevOpsエンジニアとしての価値を高める手段でもあります。

今回は以上です。