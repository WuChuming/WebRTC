//
//  SocketIOManager.h
//  RTCTest
//
//  Created by WuChuMing on 2020/3/26.
//  Copyright © 2020 Shawn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,K_Message_Type) {
    K_Message_Type_Offer,
    K_Message_Type_Answer,
    K_Message_Type_Candidate,
};


typedef void(^responseBlock)(id data);

typedef void(^messageReturnBlock)(K_Message_Type msgType,id data);

@interface SocketIOManager : NSObject

+ (instancetype)shareManager;
//链接服务器
- (void)connectToServer:(NSString *)serverURL response:(responseBlock)response;
//加入房间
- (void)joinRoomWithRoomNo:(NSString *)roomNo response:(responseBlock)response;
//发送信息
- (void)sendMessage:(NSDictionary *)message toRoom:(NSString *)roomNo response:(responseBlock)response;
//离开房间
- (void)leaveRoomWithRoomNo:(NSString *)roomNo response:(responseBlock)response;
//设置满人回调
- (void)setRoomFullAck:(responseBlock)response;
//设置其它人登陆房间回调
- (void)setOtherJoinAck:(responseBlock)response;
//设置获取消息响应回调
- (void)setAnswerAck:(messageReturnBlock)response;
//设置结束响应回调
- (void)setLeaveAck:(responseBlock)response;

@end

NS_ASSUME_NONNULL_END
