//
//  Config.h
//  live_demo
//
//  Created by lee on 2018/2/27.
//  Copyright © 2018年 example. All rights reserved.
//

#ifndef Config_h
#define Config_h


// leancloud
//#define LEANCLOUD_APPLICATION_ID @"IjgmFwP3wfoesNIRGq9nvVfs-gzGzoHsz"
//#define LEANCLOUD_CLIENT_KEY @"Ngj5YmpXNTcl91jSXskWr1fV"

#define LEANCLOUD_APPLICATION_ID @"LYqS7pBKQJ2efag7vzEAqxT2-gzGzoHsz"
#define LEANCLOUD_CLIENT_KEY @"UEtxc8c540kCRwKIfFSl21UO"

// 观众对问题的反馈 表结构
#define PROBLEMRESULT_TABLE_NAME @"ProblemResult"
#define PROBLEMRESULT_PROBLEM_COL_NAME @"Problem"
#define PROBLEMRESULT_ANSWERKEY_COL_NAME @"AnswerKey"
#define PROBLEMRESULT_ANSWERCOUNTKEY_COL_NAME @"AnswerCount"

// 问题 表结构
#define PROBLEMLIST_TABLE_NAME  @"ProblemList"
#define PROBLEMLIST_PROBLEMTITLE_NAME  @"ProblemTitle"
#define PROBLEMLIST_SERIALNUMBER_NAME  @"SerialNumber"
#define PROBLEMLIST_TUREANSWER_NAME  @"TureAnswer"
#define PROBLEMLIST_PROBLEANSWER_NAME  @"ProblemAnswer"


// 环信 app key
#define EASEMOB_APP_KEY @"1116180226099339#livedemo"
// 环信中推送证书的名字
#define EASEMOB_CERTNAME @"testapp"


// stream
#define STREAM_URL_PUSH @"rtmp://pili-publish.hd.zhaojianfeng.cn/hdtraining/20171229"
#define STREAM_URL_PULL @"rtmp://pili-live-rtmp.hd.zhaojianfeng.cn/hdtraining/20171229"
//#define STREAM_URL_PUSH @"rtmp://192.168.0.103/live/1598"
//#define STREAM_URL_PULL @"rtmp://192.168.0.103/live/1598"


#endif /* Config_h */
