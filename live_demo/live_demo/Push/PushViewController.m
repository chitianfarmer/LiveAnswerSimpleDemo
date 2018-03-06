//
//  PushViewController.m
//  live_demo
//
//  Created by lee on 2018/2/26.
//  Copyright © 2018年 example. All rights reserved.
//

#import "PushViewController.h"
#import <AVOSCloud/AVOSCloud.h>
#import <HyphenateLite/HyphenateLite.h>
#import <PLMediaStreamingKit/PLMediaStreamingKit.h>
#import "Preset.h"
#import "Config.h"

@interface PushViewController () <EMChatroomManagerDelegate>

@property (nonatomic, strong) PLMediaStreamingSession *session;

@end

@implementation PushViewController
{
    NSMutableArray* _allUsersArray;
    AVObject* _problem1;
    AVObject* _problem2;
    NSTimer* _timerCheckResult;
    
    
    int problem_1_A;
    int problem_1_B;
    int problem_2_A;
    int problem_2_B;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loginEasemob];
    
    [self setupPushStream];
    [self startStreaming];
    
    if (!_allUsersArray) {
        _allUsersArray = [[NSMutableArray alloc]init];
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self leaveChatRoom];
    if (_timerCheckResult) {
        [_timerCheckResult invalidate];
    }
    [self stopStreaming];
    [self.session.previewView removeFromSuperview];
    [self.session destroy];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - problem
- (void)updateResultUI:(NSString*)problemKey answerKey:(NSString*)answerKey answerCount:(int)answerCount {
    if ([problemKey isEqualToString:PROBLEM_KEY_1]) {
        if ([answerKey isEqualToString:PROBLEM_ANSWER_KEY_A]) {
            problem_1_A = answerCount;
        } else if ([answerKey isEqualToString:PROBLEM_ANSWER_KEY_B]) {
            problem_1_B = answerCount;
        }
        self.LabResult1.text = [NSString stringWithFormat:@"统计:A(%d) B(%d)", problem_1_A,problem_1_B];
    } else if ([problemKey isEqualToString:PROBLEM_KEY_2]) {
        if ([answerKey isEqualToString:PROBLEM_ANSWER_KEY_A]) {
            problem_2_A = answerCount;
        } else if ([answerKey isEqualToString:PROBLEM_ANSWER_KEY_B]) {
            problem_2_B = answerCount;
        }
        self.LabResult2.text = [NSString stringWithFormat:@"统计:A(%d) B(%d)", problem_2_A,problem_2_B];
    } else {
        NSLog(@"未知的问题KEY");
        return;
    }
}
- (void)checkReuslt2:(NSString*)problemObjId problemKey:(NSString*)problemKey{
    AVQuery *query = [AVQuery queryWithClassName:PROBLEMRESULT_TABLE_NAME];
    [query whereKey:PROBLEMRESULT_PROBLEM_COL_NAME equalTo:[AVObject objectWithClassName:ANCHORPROBLEM_TABLE_NAME objectId:problemObjId]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (AVObject *result in objects) {
                NSString* answerKey = [result objectForKey:PROBLEMRESULT_ANSWERKEY_COL_NAME];
                NSNumber* answerCount = [result objectForKey:PROBLEMRESULT_ANSWERCOUNTKEY_COL_NAME];
                [self updateResultUI:problemKey answerKey:answerKey answerCount:answerCount.intValue];
            }
        } else {
            NSLog(@"查询问题反馈失败S");
        }
    }];
}
- (void)checkResult:(NSTimer *)timer {
    if (_problem1) {
        [self checkReuslt2:_problem1.objectId problemKey:PROBLEM_KEY_1];
    }
    if (_problem2) {
        [self checkReuslt2:_problem2.objectId problemKey:PROBLEM_KEY_2];
    }
}
- (void)sendProblem:(NSString*)problemId {
    if (!_allUsersArray || _allUsersArray.count <= 0) {
        return;
    }
    if (!_timerCheckResult) {
        _timerCheckResult = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkResult:) userInfo:nil repeats:YES];
    }
    
    EMCmdMessageBody *body = [[EMCmdMessageBody alloc] initWithAction:problemId];
    NSString *from = [[EMClient sharedClient] currentUsername];
    
    for (int i=0; i<_allUsersArray.count; i++) {
        EMMessage *message = [[EMMessage alloc] initWithConversationID:_allUsersArray[i] from:from to:_allUsersArray[i] body:body ext:nil];
        message.chatType = EMChatTypeChat;
        [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:^(EMMessage *aMessage, EMError *aError) {
            if (!aError) {
                NSLog(@"CMD消息发送成功");
            } else {
                NSLog(@"CMD消息发送失败");
            }
        }];
    }
}
- (void)createProblemResult:(AVObject*) problem answerKey:(NSString*)answerKey {
    AVObject *problemResult = [[AVObject alloc] initWithClassName:PROBLEMRESULT_TABLE_NAME];
    [problemResult setObject:problem forKey:PROBLEMRESULT_PROBLEM_COL_NAME];
    [problemResult setObject:answerKey forKey:PROBLEMRESULT_ANSWERKEY_COL_NAME];
    [problemResult setObject:@0 forKey:PROBLEMRESULT_ANSWERCOUNTKEY_COL_NAME];
    [problemResult saveInBackground];
}
- (AVObject*)createProblem:(NSString*)problemKey {
    AVObject* problem = [AVObject objectWithClassName:ANCHORPROBLEM_TABLE_NAME];
    [problem setObject:problemKey forKey:ANCHORPROBLEM_KEY_COL_NAME];
    [problem save];
    
    // 新增答案统计记录
    [self createProblemResult:problem answerKey:PROBLEM_ANSWER_KEY_A];
    [self createProblemResult:problem answerKey:PROBLEM_ANSWER_KEY_B];
    
    return problem;
}
- (IBAction)Send1:(id)sender {
    if (!_problem1) {
        _problem1 = [self createProblem:PROBLEM_KEY_1];
    }
    [self sendProblem:_problem1.objectId];
}
- (IBAction)Send2:(id)sender {
    if (!_problem2) {
        _problem1 = [self createProblem:PROBLEM_KEY_2];
    }
    [self sendProblem:_problem2.objectId];
}

#pragma mark - easemob
- (void)updateUsers:(NSString*)cursor {
    if (!cursor) {
        [_allUsersArray removeAllObjects];
    }
    [[EMClient sharedClient].roomManager getChatroomMemberListFromServerWithId:ANCHOR_ROOM_ID cursor:cursor pageSize:100 completion:^(EMCursorResult *aResult, EMError *aError) {
        if (!aError) {
            NSLog(@"获取聊天室成员成功(%ld)", aResult.list.count);
            if (aResult.list.count > 0) {
                [_allUsersArray addObjectsFromArray:aResult.list];
                if (aResult.cursor) {
                    [self updateUsers:aResult.cursor];
                }
            }
        } else {
            NSLog(@"获取聊天室成员失败");
        }
    }];
}
- (void)loginEasemob {
    [[EMClient sharedClient] loginWithUsername:ANCHOR_USERNAME password:ANCHOR_PASSWORD completion:^(NSString *aUsername, EMError *aError) {
        if (!aError) {
            NSLog(@"登录成功");
            [self enterChatRoom];
        } else {
            NSLog(@"登录失败");
        }
    }];
}
- (void)enterChatRoom {
    [[EMClient sharedClient].roomManager addDelegate:self delegateQueue:nil];
    [[EMClient sharedClient].roomManager joinChatroom:ANCHOR_ROOM_ID completion:^(EMChatroom *aChatroom, EMError *aError) {
        if (!aError) {
            NSLog(@"进入聊天室成功");
            [self updateUsers:nil];
        } else {
            NSLog(@"进入聊天室失败");
        }
    }];
}
- (void)leaveChatRoom {
    [[EMClient sharedClient].roomManager removeDelegate:self];
    [[EMClient sharedClient].roomManager leaveChatroom:ANCHOR_ROOM_ID completion:^(EMError *aError) {
        if (!aError) {
            NSLog(@"离开聊天室成功");
        } else {
            NSLog(@"离开聊天室失败");
        }
    }];
}
- (void)userDidJoinChatroom:(EMChatroom *)aChatroom user:(NSString *)aUsername {
    if (![_allUsersArray containsObject:aUsername]) {
        [_allUsersArray addObject:aUsername];
    }
}

- (void)userDidLeaveChatroom:(EMChatroom *)aChatroom user:(NSString *)aUsername {
    if ([_allUsersArray containsObject:aUsername]) {
        [_allUsersArray removeObject:aUsername];
    }
}

#pragma mark - push
- (void)setupPushStream {
    if (!self.session) {
        PLVideoCaptureConfiguration *videoCaptureConfiguration = [PLVideoCaptureConfiguration defaultConfiguration];
        PLAudioCaptureConfiguration *audioCaptureConfiguration = [PLAudioCaptureConfiguration defaultConfiguration];
        PLVideoStreamingConfiguration *videoStreamingConfiguration = [PLVideoStreamingConfiguration defaultConfiguration];
        PLAudioStreamingConfiguration *audioStreamingConfiguration = [PLAudioStreamingConfiguration defaultConfiguration];
        videoCaptureConfiguration.position = AVCaptureDevicePositionFront;
        self.session = [[PLMediaStreamingSession alloc] initWithVideoCaptureConfiguration:videoCaptureConfiguration audioCaptureConfiguration:audioCaptureConfiguration videoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration stream:nil];
        
        [self.ViewVideo addSubview:self.session.previewView];
    }
}
- (void)startStreaming {
    if (!self.session.isStreamingRunning) {
        NSURL *pushURL = [NSURL URLWithString:STREAM_URL_PUSH];
        [self.session startStreamingWithPushURL:pushURL feedback:^(PLStreamStartStateFeedback feedback) {
            if (feedback == PLStreamStartStateSuccess) {
                NSLog(@"Streaming started.");
            }
            else {
                NSLog(@"Oops.");
            }
        }];
    }
}
- (void)stopStreaming {
    if (self.session.isStreamingRunning) {
        [self.session stopStreaming];
    }
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

