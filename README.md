# LiveAnswerSimpleDemo
实现一个简单的在手机上直播推拉流答题功能的demo

## 1 项目初衷

目前直播答题的风头正盛，作为一个技术狗就跃跃欲试想做一个类似的demo，也希望对有同样需求的小伙伴提供些许思路和一定的帮助。

## 2 方案架构

![](https://thumbnail0.baidupcs.com/thumbnail/942e4d7c22579c463bd06f8197a0afaf?fid=2505445054-250528-371188459423429&time=1519808400&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-6pmxKVgtvghKtJt32brHKTnSugk%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=1361613201116581468&dp-callid=0&size=c710_u400&quality=100&vuk=-&ft=video.png)

## 3 功能介绍

demo使用了环信IM SDK和七牛云的直播SDK以及leancloud，环信用来创建聊天室分为主播和观众，观众加入聊天室观看直播，通过IM下发答题指令观众抽取题目开始答题。七牛云用来直播推拉流。leancloud后台操作，用来下发题目和上传统计数据。
百万英雄、芝士超人这些都是用PC进行推流的，然后手机客户端拉流播放。此demo只是做的一个简版，直接使用手机进行推拉流。代码逻辑可以参考方案架构的图，在此基础上做了一个简版，实现了手机直播和手机答题。

### 注意

运行此demo需要推拉流地址，demo中已存在的地址已经过期无效。首先需要注册一个七牛云的账号，3个工作日内审核完成，然后创建测试的推拉流地址进行测试，并需要在工程的config.h文件中修改对应的地址宏定义。

如果需要在自己的项目中直接使用此demo，则需要注册环信账号并把appkey修改为自己的项目即可。(leancloud可以去掉换成自己的业务服务器)

