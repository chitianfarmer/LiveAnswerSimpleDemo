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
    AVObject* _problem;
    EMChatroom *_chatRoom;
    NSInteger _problemIndex;
    
    int problem_A;
    int problem_B;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _problemIndex = 0;
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
    [self stopStreaming];
    [self.session.previewView removeFromSuperview];
    [self.session destroy];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - problem
- (void)updateResultUIWithAnswerKey:(NSString*)answerKey answerCount:(int)answerCount {
    if ([answerKey isEqualToString:PROBLEM_ANSWER_KEY_A]) {
        problem_A = answerCount;
    } else if ([answerKey isEqualToString:PROBLEM_ANSWER_KEY_B]) {
        problem_B = answerCount;
    }
    self.resultLab.text = [NSString stringWithFormat:@"统计:A(%d) B(%d)", problem_A,problem_B];
}
- (void)checkReuslt:(NSNumber*)problemKey{
    AVQuery *query = [AVQuery queryWithClassName:PROBLEMRESULT_TABLE_NAME];
    [query whereKey:PROBLEMRESULT_PROBLEM_COL_NAME equalTo:problemKey];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (AVObject *result in objects) {
                NSString* answerKey = [result objectForKey:PROBLEMRESULT_ANSWERKEY_COL_NAME];
                NSNumber* answerCount = [result objectForKey:PROBLEMRESULT_ANSWERCOUNTKEY_COL_NAME];
                [self updateResultUIWithAnswerKey:answerKey answerCount:answerCount.intValue];
            }
        } else {
            NSLog(@"查询问题反馈失败S");
        }
    }];
}

- (void)sendProblem:(NSString*)problemId type:(NSString *)type{
    if (!_allUsersArray || _allUsersArray.count <= 0) {
        return;
    }
    
    EMCmdMessageBody *body = [[EMCmdMessageBody alloc] initWithAction:problemId];
    NSString *from = [[EMClient sharedClient] currentUsername];
    
    for (int i=0; i<_allUsersArray.count; i++) {
        EMMessage *message = [[EMMessage alloc] initWithConversationID:ANCHOR_ROOM_ID from:from to:_chatRoom.chatroomId body:body ext:@{@"type":type}];
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
- (void)createProblemResult:(AVObject*)problem answerKey:(NSString*)answerKey {
    AVObject *problemResult = [[AVObject alloc] initWithClassName:PROBLEMRESULT_TABLE_NAME];
    [problemResult setObject:[problem objectForKey:PROBLEMLIST_SERIALNUMBER_NAME] forKey:PROBLEMRESULT_PROBLEM_COL_NAME];
    [problemResult setObject:answerKey forKey:PROBLEMRESULT_ANSWERKEY_COL_NAME];
    [problemResult setObject:@0 forKey:PROBLEMRESULT_ANSWERCOUNTKEY_COL_NAME];
    [problemResult saveInBackground];
}
- (AVObject*)findProblem:(NSNumber *)problemKey {
    AVQuery *query = [AVQuery queryWithClassName:PROBLEMLIST_TABLE_NAME];
    [query whereKey:PROBLEMLIST_SERIALNUMBER_NAME equalTo:problemKey];
    AVObject* problem = [query getFirstObject];
    
    // 新增答案统计记录
    [self createProblemResult:problem answerKey:PROBLEM_ANSWER_KEY_A];
    [self createProblemResult:problem answerKey:PROBLEM_ANSWER_KEY_B];
    
    return problem;
}
- (IBAction)sendQusetion:(id)sender {
    if (_problemIndex == 0) {
        _problemIndex = 1;
    }else if (_problemIndex >= 12){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"题目已全部答完" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }else{
        _problemIndex++;
    }
    
    [_questionBtn setTitle:[NSString stringWithFormat:@"发布问题(%ld)",(long)_problemIndex] forState:UIControlStateNormal];
    _resultLab.text = @"统计:A(0) B(0)";
    
    if (!_problem) {
        _problem = [self findProblem:[NSNumber numberWithInteger:_problemIndex]];
    }
    [self sendProblem:_problem.objectId type:@"question"];
}
- (IBAction)announceAnswer:(id)sender {
    
    if (_problemIndex == 0 || _problemIndex >= 12) {
        return;
    }
    [_answerBtn setTitle:[NSString stringWithFormat:@"公布答案(%ld)",(long)_problemIndex] forState:UIControlStateNormal];
    [self checkReuslt:[NSNumber numberWithInteger:_problemIndex]];
    [self sendProblem:_problem.objectId type:@"answer"];
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
            _chatRoom = [EMChatroom chatroomWithId:aChatroom.chatroomId];
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
        
        [self.videoView addSubview:self.session.previewView];
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
