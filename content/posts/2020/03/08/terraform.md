---
title : "クラウドエンジニアはTerraformを使うべし"
date  : 2020-03-08T01:53:31+01:00
description: ""
draft : false
tags  : [
    "blog",
    "terraform",
    "serverless",
]
categories: [
    "雑記",
    "エンジニア思考"
]
meta_image: "/thumbnails/2020-03-08-terraform.png"
---

今回はクラウドエンジニアなら絶対に身に付けるべき「インフラのコード化」というテーマで書きます。

# インフラのコード化って？

今の時代「クラウド」という言葉がかなり流行っていますが、この新しいサービス上で色んなものを作ることができます。

更に作ったものが増えたり、複雑になるほど管理がものすごく大変で面倒なことになります。

インフラのコード化（通称IAC; Infra As Code）はそういった悩みを解決してくれるベストプラクティスです。

これができないクラウドエンジニアは、正直キャリアアップはかなり難しいと考えて下さい。

## どんな選択肢があるの？

今現段階では次の3つの選択肢があります。

- Terraform (色々使える)
- Cloudformation (AWSのみ)
- CDK (AWSのみ)

### Terraform (色々使える)

インフラのコード化で1番王道なのがTerraformです。これが使えるクラウドサービスはたくさんあります。

例えば、AWS(Amazon Web Services), GCP (Google Cloud Computing), Azureなど。

そしてあまり知られてないのが、[REST APIもコード化](https://github.com/Mastercard/terraform-provider-restapi)できるんです。

とにかく色んなものをコード化できるのがTerraformです。

### Cloudformation (AWSのみ)

AWSで使えるコード化はCloudformationですが、正直エラーが出た時のトラブルシューティングがかなり玄人向けです。(エラーメッセージがかなり分かりにくい)

そして適用する前のコードチェックも結構しょぼくて素人には学習コストが高かったりします。

唯一の利点といえば失敗時にロールバック(作ったやつを消してくれる)機能があることでしょうか。

Cloudformationは[Troposphere](https://github.com/cloudtools/troposphere)と組み合わせるのがオススメ。

これはCloudformationのめちゃくちゃ読みにくい形式をPythonでコード化できます。

### CDK (AWSのみ)
最近知ったのですが[CDK(Cloud Development Kit)](https://docs.aws.amazon.com/cdk/latest/guide/home.html)という新しいツールがAWSから出てますね。

ざっとみた感じ、TroposphereがPython以外の言語でも書けるようになる、と言ったところでしょうか。

## どれがオススメ？

断然Terraformです。これは学習コストも少なく、かつ非常に分かりやすいので学ばない他ありません。

# どう勉強すべき？

色んな教材を見て勉強するよりも、実際にTerraformを試してみるべきです。

「Terraform サービス名」で検索すると大抵上の方にサンプルが出てくるのでそれを真似しながら、ドキュメントを読みながら進めていくことをオススメします。

いくつかのサービスを試しにTerraforming(Terraformする)ことで、どう言った感じで使われているのかを学ぶことが可能です。

以上です。
