---
title : "Vagrantで開発環境を作ろう！"
date  : 2020-03-23T07:51:37+01:00
draft : false
tags  : [
    "vagrant",
]
categories: [
    "開発環境"
]
meta_image  : "/thumbnails/2020-03-23-vagrant.png"
description : ""
---

今回はVagrantで本サーバレスブログ向けの開発環境を作ろうと思います。

Vagrantを知らない人向けの簡単な説明ですが、これは「自分のパソコンに仮想のパソコンを立ち上げる」ものだと考えてください。

自分のメインのパソコンと違って、間違ったソフトウェア(Rubyなど)バージョンをインストールしても、最初から作り直すことができます。

つまり初学者がハマりやすい「環境・バージョンの罠」を回避することが可能です。

今回作成した成果物はすべてGithub「[amezousan/vagrant-dev](https://github.com/amezousan/vagrant-dev)」で確認できます。

# Vagrantの導入
## 検証環境
今回使用するOS・ソフトウェアのバージョンは次の通りです。

Item          |Version|
---           |---|
macOS Catalina|10.15.3(CPU: Dual-Core i5, Memory: 16GB)|
Vagrant       |2.2.4|  
VirtualBox    |6.0.4|

各ソフトのインストール手順は省略します。

## 参考にしたもの
[【Vagrant】vagrantを導入しよう](https://qiita.com/ohuron/items/057b74a42b182b200ae6)が非常に参考になります。

## 導入手順
### 1. 初期化
1. 任意のフォルダを作ってそこでVagrantに必要なファイルを置きます。
```sh
$ mkdir vagrant-dev
$ cd test
```

2. 初期化します。
```sh
$ vagrant init
$ ls
Vagrantfile
```

3. Vagrantfileの`config.vm.box = "base"`を`bento/ubuntu-18.04`に変更。

4. 立ち上げてログインしてみます。

```sh
$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'bento/ubuntu-18.04'...
==> default: Matching MAC address for NAT networking...
...

$ vagrant ssh

vagrant@vagrant:~$ date
Mon Mar 23 07:37:09 UTC 2020
vagrant@vagrant:~$ uname -a
Linux vagrant 4.15.0-65-generic #74-Ubuntu SMP Tue Sep 17 17:06:04 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux
```

ちなみにVirtualBoxアプリを開くと仮想マシンが動いてるのが分かります。

{{<figure src="/images/2020/03-23-vagrant-01.png">}}

### 2. カスタマイズする
最低限やりたいことは以下の通り

- プライベートIPの割当
- ゲストOSの性能を指定する
- 開発に必要なソフトウェアのインストール&コード化
  - git, terraform, apex, aws-cli, python3, hugo
- 本体OSとの共有フォルダ作成
- キャッシュ機能の有効化

#### 完成品

- フォルダ・ファイル構成

```sh
$ tree vagrant-dev/
vagrant-dev/
├── Vagrantfile
├── ansible
│   ├── all.yml
│   ├── inventories
│   │   └── hosts
│   └── roles
│       └── common
│           └── tasks
│               └── main.yml
└── shared
    ├── hugo-serverless-blog
    └── serverless-blog-in-aws
```

- Vagrantfile

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  id = "ubuntu-18-04"
  config.vm.box = "bento/ubuntu-18.04"
  config.vm.hostname = "serverless"
  config.vm.network "private_network", ip: "192.168.33.10"

  # Create a forwarded port mapping which allows access to a specific port
  config.vm.network "forwarded_port", guest: 1313, host: 1313, host_ip: "127.0.0.1"

  # Share an additional folder to the guest VM.
  config.vm.synced_folder "../vagrant-dev", "/home/vagrant/vagrant-dev",
                            create: true, owner: 'vagrant', group: 'vagrant'

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus   = 1
    # Internet was too slow
    # https://serverfault.com/questions/495914/vagrant-slow-internet-connection-in-guest
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # Enable Cache feature if you have the cache plugin.
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  # Play ansible
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook       = "./ansible/all.yml"
    ansible.limit          = "localhost"
    ansible.inventory_path = "./ansible/inventories/hosts"
  end
end

```

以下解説です。

#### プライベートIPの割当

- Vagrantfileの「private_network」部分をコメントアウト。

```ruby
config.vm.network "private_network", ip: "192.168.33.10"
```

> ここで指定されるIPアドレスはパソコンによって異なる可能性があります。

#### ゲストOSの性能を指定する

- Vagrantfileに追記
```ruby
config.vm.provider "virtualbox" do |v|
  v.memory = 2048
  v.cpus   = 1
end
```

参考: [VBoxManage Customizations](https://www.vagrantup.com/docs/virtualbox/configuration.html#vboxmanage-customizations)

#### 開発に必要なソフトウェアのインストール&コード化

- 共通ロールフォルダを作成

```sh
$ mkdir -p  ansible/roles/common/tasks/
$ mkdir -p  ansible/inventries/
$ touch ansible/roles/common/tasks/main.yml
$ touch ansible/all.yml
$ touch ansible/inventries/hosts
$ tree vagrant-dev/
vagrant-dev/
├── Vagrantfile
├── ansible
│   ├── all.yml
│   ├── inventories
│   │   └── hosts
│   └── roles
│       └── common
│           └── tasks
│               └── main.yml
└── shared
    ├── hugo-serverless-blog
    └── serverless-blog-in-aws
```

- hosts

```yml
[clients]
127.0.0.1 ansible_connection=local
```

- all.yml

```yml
---
- name: setup local
  hosts: localhost
  become: true
  vars:
    # A to Z
    apex_ver      : '1.0.0-rc3'
    aws_cli_ver   : '1.18.26'
    hugo_ver      : '0.68.2'
    terraform_ver : '0.12.24'
  roles:
    - common
```

- main.yml

```yml
---
  - name: Add git repositories to fetch the latest git package
    apt_repository:
      repo: ppa:git-core/ppa

  - name: Install pip3
    apt:
      name: python3-pip
      state: latest

  - name: Install Unzip
    apt:
      name: unzip
      state: latest

  - name: Download and unarchive then install Terraform
    file:
      path: /tmp/terraform-{{ terraform_ver }}
      state: directory
  - unarchive:
      src: https://releases.hashicorp.com/terraform/{{ terraform_ver }}/terraform_{{ terraform_ver }}_linux_amd64.zip
      dest: /tmp/terraform-{{ terraform_ver }}
      remote_src: yes
  - copy:
      src: /tmp/terraform-{{ terraform_ver }}/terraform
      dest: /usr/local/bin/terraform
      owner: root
      group: root
      mode: 0755

  - name: Download and unarchive then install Apex
    file:
      path: /tmp/apex-{{ apex_ver }}
      state: directory
  - unarchive:
      src: https://github.com/apex/apex/releases/download/v{{ apex_ver }}/apex_{{ apex_ver }}_linux_amd64.tar.gz
      dest: /tmp/apex-{{ apex_ver }}
      remote_src: yes
  - copy:
      src: /tmp/apex-{{ apex_ver }}/apex
      dest: /usr/local/bin/apex
      owner: root
      group: root
      mode: 0755

  - name: Download and unarchive then install Hugo
    file:
      path: /tmp/hugo-{{ hugo_ver }}
      state: directory
  - unarchive:
      src: https://github.com/gohugoio/hugo/releases/download/v{{ hugo_ver }}/hugo_{{ hugo_ver }}_Linux-64bit.tar.gz
      dest: /tmp/hugo-{{ hugo_ver }}
      remote_src: yes
  - copy:
      src: /tmp/hugo-{{ hugo_ver }}/hugo
      dest: /usr/local/bin/hugo
      owner: root
      group: root
      mode: 0755

  - name: Install AWS CLI
    command: python3 -m pip install awscli=={{ aws_cli_ver }}

  - name: Update and upgrade apt packages
    become: true
    apt:
      upgrade: yes
      update_cache: yes
```

- Vagrantfile (Ansibleでコード化)

```ruby
# Play ansible
config.vm.provision "ansible_local" do |ansible|
  ansible.playbook       = "./ansible/all.yml"
  ansible.limit          = "localhost"
  ansible.inventory_path = "./ansible/inventories/hosts"
end
```

> ansible.inventory_pathにはvagrantのデフォルトで存在するファイルを指定。自作しても良いが既にあるものを使う。

- [1コマンドで作った。Vagrant + Ansible によるコードによる構成管理](https://sitest.jp/blog/?p=5094)

#### 本体OSとの共有フォルダ作成

- Vagrantfile (sharedフォルダは手動で作成)

```ruby
# Share an additional folder to the guest VM.
config.vm.synced_folder "./shared", "/home/vagrant/shared",
                          create: true, owner: 'vagrant', group: 'vagrant'
```

#### キャッシュ機能の有効化

[Vagrant のプロビジョン時間を削減する vagrant-cachier プラグインが良い](http://www.1x1.jp/blog/2014/09/vagrant-cachier-plugin.html)

- Vagrantfile & `$ vagrant plugin install vagrant-cachier`

```ruby
# Enable Cache feature if you have the cache plugin.
if Vagrant.has_plugin?("vagrant-cachier")
  config.cache.scope = :box
end
```

# 実際に使ってみる

- 設定を反映、ログイン

```sh
# ネットワーク系の設定は一旦停止または再起動させないと反映されません。
$ vagrant halt
$ vagrant up
$ vagrant provision
$ vagrant ssh
```

## Hugoサーバーを立ち上げる

```sh
$ pwd
/home/vagrant/shared
$ git clone https://github.com/amezousan/hugo-serverless-blog.git
$ cd hugo-serverless-blog/
$ hugo server --bind=0.0.0.0 --baseURL=http://127.0.0.1:1313
```

> ハマったポイント①: `--bind=0.0.0.0`がないと、ホストOS側からのアクセスをなぜがゲストOSは「SYN」を受け取った後「RST」パケットを送り、接続を切ってしまいます。Apacheサーバでは起きなかったのでHugo Serverコマンドに何かあることが予想されます。

> ハマったポイント②: `--baseURL`を指定することで、一部のリソース(e.g., font-awesome)をきちんと読み込めるようにしています。

ホストOS側で「http://127.0.0.1:1313」にアクセスして、きちんと表示されれば成功！

{{<figure src="/images/2020/03-23-vagrant-02.png">}}

## 解決したい課題

- [ ] `hugo server`コマンドを使ってもホストOS側のエディタで編集するとリアルタイムで反映されない。
  - vimでmarkdownを書く環境を整えてないので、ひとまずホストOS側でサーバを立ち上げる方針で行きます。
- [ ] 別レポジトリの[amezousan/hugo-serverless-blog](https://github.com/amezousan/hugo-serverless-blog)と[amezousan/serverless-blog-in-aws](https://github.com/amezousan/serverless-blog-in-aws)の開発環境(プラグインとかIAM系とか)を整える。

>  vagrant上のエディタでしか更新は反映されません。`vim`などを使ってmarkdownを書く必要があります。vimmerになる良い機会かもしれませんね！
