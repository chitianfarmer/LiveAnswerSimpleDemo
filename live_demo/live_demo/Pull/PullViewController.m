//
//  PullViewController.m
//  live_demo
//
//  Created by lee on 2018/2/26.
//  Copyright © 2018年 example. All rights reserved.
//

#import "PullViewController.h"
#import <AVOSCloud/AVOSCloud.h>
#import <HyphenateLite/HyphenateLite.h>
#import <PLPlayerKit/PLPlayerKit.h>
#import "Preset.h"
#import "Config.h"

@interface PullViewController () <EMChatroomManagerDelegate, EMChatManagerDelegate,PLPlayerDelegate>

@property (nonatomic, strong) PLPlayer  *player;
@end

@implementation PullViewController
{
    AVObject* _problem;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loginEasemob];
    [self setupPullStream];
    [self startStreaming];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self leaveChatRoom];
    [self stopStreaming];
    [self.player.playerView removeFromSuperview];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - problem
- (IBAction)ClickAnswer1:(id)sender {
    self.ViewProblem.hidden = true;
    [self updateProblemResult:PROBLEM_ANSWER_KEY_A];
}
- (IBAction)ClickAnswer2:(id)sender {
    self.ViewProblem.hidden = true;
    [self updateProblemResult:PROBLEM_ANSWER_KEY_B];
}
- (void)updateProblemResult:(NSString*)answerKey {
    AVQuery *problemQuery = [AVQuery queryWithClassName:PROBLEMRESULT_TABLE_NAME];
    [problemQuery whereKey:PROBLEMRESULT_PROBLEM_COL_NAME equalTo:_problem];
    AVQuery *answerQuery = [AVQuery queryWithClassName:PROBLEMRESULT_TABLE_NAME];
    [answerQuery whereKey:PROBLEMRESULT_ANSWERKEY_COL_NAME equalTo:answerKey];
    AVQuery *query = [AVQuery andQueryWithSubqueries:[NSArray arrayWithObjects:problemQuery,answerQuery,nil]];
    [query getFirstObjectInBackgroundWithBlock:^(AVObject *object, NSError *error) {
        if (!error && object) {
            NSString* nowAnswerKey = [object objectForKey:PROBLEMRESULT_ANSWERKEY_COL_NAME];
            if ([nowAnswerKey isEqualToString:answerKey]) {
                [object incrementKey:PROBLEMRESULT_ANSWERCOUNTKEY_COL_NAME];
                [object saveInBackground];
            }
        } else {
            NSLog(@"查询问题反馈失败");
        }
    }];
}

- (void)showProblem:(NSString*)problemKey {
    if ([problemKey isEqualToString:PROBLEM_KEY_1]) {
        self.LabTitle.text = PROBLEM_TITLE_1;
        [self.ButtonAnswer1 setTitle:PROBLEM_ANSWER_1_A forState:UIControlStateNormal];
        [self.ButtonAnswer2 setTitle:PROBLEM_ANSWER_1_B forState:UIControlStateNormal];
    } else if ([problemKey isEqualToString:PROBLEM_KEY_2]) {
        self.LabTitle.text = PROBLEM_TITLE_2;
        [self.ButtonAnswer1 setTitle:PROBLEM_ANSWER_2_A forState:UIControlStateNormal];
        [self.ButtonAnswer2 setTitle:PROBLEM_ANSWER_2_B forState:UIControlStateNormal];
    } else {
        NSLog(@"未知的问题KEY");
        return;
    }
    self.ViewProblem.hidden = false;
}
- (void)selectAndShowProblem:(NSString*)problemId {
    AVQuery *query = [AVQuery queryWithClassName:ANCHORPROBLEM_TABLE_NAME];
    [query getObjectInBackgroundWithId:problemId block:^(AVObject *object, NSError *error) {
        if (!error) {
            _problem = object;
            NSString* problemKey = [object objectForKey:ANCHORPROBLEM_KEY_COL_NAME];
            [self showProblem:problemKey];
        } else {
            NSLog(@"获取问题失败");
        }
    }];
}
- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages {
    NSLog(@"收到CMD消息");
    for (EMMessage *message in aCmdMessages) {
        EMCmdMessageBody *body = (EMCmdMessageBody *)message.body;
        [self selectAndShowProblem:body.action];
    }
}

#pragma mark - easemob
- (void)loginEasemob {
    [[EMClient sharedClient] loginWithUsername:AUDIENCE_USERNAME password:AUDIENCE_PASSWORD completion:^(NSString *aUsername, EMError *aError) {
        if (!aError) {
            NSLog(@"登录成功");
            [self enterChatRoom];
        } else {
            NSLog(@"登录失败");
        }
    }];
}
- (void)enterChatRoom {
    [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
    //[[EMClient sharedClient].roomManager addDelegate:self delegateQueue:nil];
    [[EMClient sharedClient].roomManager joinChatroom:ANCHOR_ROOM_ID completion:^(EMChatroom *aChatroom, EMError *aError) {
        if (!aError) {
            NSLog(@"进入聊天室成功");
        } else {
            NSLog(@"进入聊天室失败");
        }
    }];
}
- (void)leaveChatRoom {
    [[EMClient sharedClient].chatManager removeDelegate:self];
    //[[EMClient sharedClient].roomManager removeDelegate:self];
    [[EMClient sharedClient].roomManager leaveChatroom:ANCHOR_ROOM_ID completion:^(EMError *aError) {
        if (!aError) {
            NSLog(@"离开聊天室成功");
        } else {
            NSLog(@"离开聊天室失败");
        }
    }];
}

#pragma mark - pull
- (void)setupPullStream {
    if (!self.player) {
        PLPlayerOption *option = [PLPlayerOption defaultOption];
        [option setOptionValue:@15 forKey:PLPlayerOptionKeyTimeoutIntervalForMediaPackets];
        NSURL *url = [NSURL URLWithString:STREAM_URL_PULL];
        self.player = [PLPlayer playerWithURL:url option:option];
        self.player.delegate = self;
        self.player.delegateQueue = dispatch_get_main_queue();
        self.player.backgroundPlayEnable = true;
        [self.ViewVideo addSubview:self.player.playerView];
    }
}

- (void)startStreaming {
    [self.player play];
}
- (void)stopStreaming {
    [self.player stop];
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
