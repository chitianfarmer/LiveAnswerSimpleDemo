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
    NSInteger _answerIndex;
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
- (IBAction)ClickAnswer1:(UIButton *)sender {
    [self updateProblemResult:PROBLEM_ANSWER_KEY_A];
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(delayAction) userInfo:nil repeats:NO];
}
- (IBAction)ClickAnswer2:(UIButton *)sender {
    [self updateProblemResult:PROBLEM_ANSWER_KEY_B];
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(delayAction) userInfo:nil repeats:NO];
}
- (void)updateProblemResult:(NSString*)answerKey {
    AVQuery *problemQuery = [AVQuery queryWithClassName:PROBLEMRESULT_TABLE_NAME];
    [problemQuery whereKey:PROBLEMRESULT_PROBLEM_COL_NAME equalTo:[_problem objectForKey:PROBLEMLIST_SERIALNUMBER_NAME]];
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

- (void)selectAndShowProblem{
    NSString *title = [_problem objectForKey:PROBLEMLIST_PROBLEMTITLE_NAME];
    NSArray *proArr = [_problem objectForKey:PROBLEMLIST_PROBLEANSWER_NAME];
    _titleLab.text = title;
    [_answer1Btn setTitle:[proArr firstObject] forState:UIControlStateNormal];
    [_answer2Btn setTitle:[proArr lastObject] forState:UIControlStateNormal];
    
    self.problemView.hidden = false;
}

- (void)showProblemAnswer{
    NSNumber *trueAnswer = [_problem objectForKey:PROBLEMLIST_TUREANSWER_NAME];
    if ([trueAnswer integerValue] == 1) {
        [_answer1Btn setBackgroundColor:[UIColor greenColor]];
    }else{
        [_answer2Btn setBackgroundColor:[UIColor greenColor]];
    }
    self.problemView.hidden = false;
    
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(delayAction) userInfo:nil repeats:NO];
}

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages {
    for (EMMessage *message in aCmdMessages) {
        NSString *type = [message.ext objectForKey:@"type"];
        EMCmdMessageBody *body = (EMCmdMessageBody *)message.body;
        AVQuery *query = [AVQuery queryWithClassName:PROBLEMLIST_TABLE_NAME];
        [query getObjectInBackgroundWithId:body.action block:^(AVObject *object, NSError *error) {
            if (!error) {
                _problem = object;
                if ([type isEqualToString:@"question"]) {
                    [self selectAndShowProblem];
                }else{
                    [self showProblemAnswer];
                }
            } else {
                NSLog(@"获取问题失败");
            }
        }];
        
    }
}

- (void)delayAction{
    [_answer1Btn setBackgroundColor:[UIColor clearColor]];
    [_answer2Btn setBackgroundColor:[UIColor clearColor]];
    self.problemView.hidden = true;
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
        [self.videoView addSubview:self.player.playerView];
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
