//
//  SocketIOManager.m
//  RTCTest
//
//  Created by WuChuMing on 2020/3/26.
//  Copyright © 2020 Shawn. All rights reserved.
//

#import "SocketIOManager.h"
@import SocketIO;

#define WeakSelf __weak typeof(self) weakSelf = self;
@interface SocketIOManager()

@property (nonatomic, strong) SocketManager *manager;

//加入房间回调
@property (nonatomic, copy) responseBlock joinBlock;
//发送信息回调
@property (nonatomic, copy) responseBlock messageBlock;
//离开房间回调
@property (nonatomic, copy) responseBlock leaveBlock;
//满人回调
@property (nonatomic, copy) responseBlock fullBlock;
//满人回调
@property (nonatomic, copy) responseBlock otherJoinBlock;
//发送信息回调
@property (nonatomic, copy) messageReturnBlock msgReturn;
//bye回调
@property (nonatomic, copy) responseBlock leave;
@end

@implementation SocketIOManager

+ (instancetype)shareManager{
    static SocketIOManager *_stance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _stance = [[SocketIOManager alloc] init];
    });
    return _stance;
}


//链接服务器
- (void)connectToServer:(NSString *)serverURL response:(responseBlock)response{
      NSURL* url = [[NSURL alloc] initWithString:serverURL];
        _manager = [[SocketManager alloc] initWithSocketURL:url config:@{@"log": @YES, @"compress": @YES}];
        SocketIOClient* socket = _manager.defaultSocket;
    WeakSelf
        [socket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
//            链接成功
            if (response) {
                response(data);
            }
        }];
//    加入房间成功
        [socket on:@"joined" callback:^(NSArray* data, SocketAckEmitter* ack) {
            if (weakSelf.joinBlock) {
                weakSelf.joinBlock(data);
            }
        }];
    //    离开房间成功
    [socket on:@"bye" callback:^(NSArray* data, SocketAckEmitter* ack) {
        if (weakSelf.leave) {
            weakSelf.leave(data);
        }
    }];
    //    其它人登陆
       [socket on:@"otherjoin" callback:^(NSArray* data, SocketAckEmitter* ack) {
           if (weakSelf.otherJoinBlock) {
               weakSelf.otherJoinBlock(data);
           }
       }];
    
    //   有消息来了
          [socket on:@"message" callback:^(NSArray* data, SocketAckEmitter* ack) {
              NSDictionary *dict = data.lastObject;
              if (dict.allKeys.count > 0) {
                  NSString *type = dict[@"type"];
//                  如果是offer数据
                  if ([type isEqualToString:@"offer"]) {
                      self.msgReturn(K_Message_Type_Offer, dict);
                  } else if ([type isEqualToString:@"answer"]){
                      self.msgReturn(K_Message_Type_Answer, dict);
                  } else if ([type isEqualToString:@"candidate"]){
                      self.msgReturn(K_Message_Type_Candidate, dict);
                  }
              }
          }];
        [socket connect];
    
}
//加入房间
- (void)joinRoomWithRoomNo:(NSString *)roomNo response:(responseBlock)response{
    if (self.manager.status == SocketIOStatusConnected) {
        self.joinBlock = response;
        [self.manager.defaultSocket emit:@"join" with:@[roomNo] completion:nil];
        
    }
}
//发送信息
- (void)sendMessage:(NSDictionary *)message toRoom:(NSString *)roomNo response:(responseBlock)response{
    if (self.manager.status == SocketIOStatusConnected && message) {
           self.messageBlock = response;
        [self.manager.defaultSocket emit:@"message" with:@[roomNo,message] completion:nil];
      }
}

- (void)leaveRoomWithRoomNo:(NSString *)roomNo response:(responseBlock)response{
    if (self.manager.status == SocketIOStatusConnected) {
           self.leaveBlock = response;
        [self.manager.defaultSocket emit:@"leave" with:@[roomNo] completion:nil];
    
      }
}

//设置满人回调
- (void)setRoomFullAck:(responseBlock)response{
    self.fullBlock = response;
}

//设置其它人登陆房间回调
- (void)setOtherJoinAck:(responseBlock)response{
    self.otherJoinBlock = response;
}

//设置获取消息响应回调
- (void)setAnswerAck:(messageReturnBlock)response{
    self.msgReturn = response;
}

//设置结束响应回调
- (void)setLeaveAck:(responseBlock)response{
    self.leave = response;
}

@end
