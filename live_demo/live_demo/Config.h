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
#define LEANCLOUD_APPLICATION_ID @"IjgmFwP3wfoesNIRGq9nvVfs-gzGzoHsz"
#define LEANCLOUD_CLIENT_KEY @"Ngj5YmpXNTcl91jSXskWr1fV"

// 主播提的问题 表结构
#define ANCHORPROBLEM_TABLE_NAME @"AnchorProblem"
#define ANCHORPROBLEM_KEY_COL_NAME @"ProblemKey"

// 观众对问题的反馈 表结构
#define PROBLEMRESULT_TABLE_NAME @"ProblemResult"
#define PROBLEMRESULT_PROBLEM_COL_NAME @"Problem"
#define PROBLEMRESULT_ANSWERKEY_COL_NAME @"AnswerKey"
#define PROBLEMRESULT_ANSWERCOUNTKEY_COL_NAME @"AnswerCount"


// 环信
#define EASEMOB_APP_KEY @"1116180226099339#livedemo"
#define EASEMOB_CERTNAME @"testapp"


// stream
#define STREAM_URL_PUSH @"rtmp://pili-publish.hd.zhaojianfeng.cn/hdtraining/20171229"
//#define STREAM_URL_PULL @"rtmp://pili-publish.pf.zhaojianfeng.cn/pfdddddd/qwer"
#define STREAM_URL_PULL @"rtmp://pili-live-rtmp.hd.zhaojianfeng.cn/hdtraining/20171229"


#endif /* Config_h */
