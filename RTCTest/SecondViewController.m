//
//  SecondViewController.m
//  WebRTCLearning
//
//  Created by WuChuMing on 2020/3/25.
//  Copyright © 2020 Shawn. All rights reserved.
//

#import "SecondViewController.h"
#import <WebRTC/WebRTC.h>
#import "SocketIOManager.h"
#define WeakSelf __weak typeof(self) weakSelf = self;


@interface SecondViewController ()<RTCPeerConnectionDelegate,RTCVideoViewDelegate,RTCVideoViewShading>

@property (weak, nonatomic) IBOutlet RTCEAGLVideoView *remoteView;

@property (weak, nonatomic) IBOutlet RTCCameraPreviewView *localView;

@property (weak, nonatomic) IBOutlet UIButton *button;

@property (nonatomic, strong) RTCPeerConnectionFactory *factory;
@property (nonatomic, strong) RTCPeerConnection *pc;

@property (nonatomic, strong) RTCAudioTrack *audioTrace;
@property (nonatomic, strong) RTCVideoTrack *videoTrace;

@property (nonatomic, strong) RTCCameraVideoCapturer *capture;

@property (nonatomic, strong) RTCMediaConstraints *constraints;


@property (nonatomic, strong) RTCVideoTrack *remoteTrack;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    self.remoteView.delegate = self;
    
    self.button.layer.cornerRadius = self.button.frame.size.height/2;
    self.button.clipsToBounds = YES;
    
    
    
    //        获取数据流
    [self captureLocalMedia];
    
    
    
    // Do any additional setup after loading the view from its nib.
}


#pragma mark -----WebRTC内容---发送--

- (void)_otherJoin{
    WeakSelf
    [self.pc offerForConstraints:self.constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) {
            NSLog(@"-----------------错误了----------");
        } else {
            [weakSelf _setLocalOfferWithSdp:sdp];
        }
    }];
}
//设置本地sdp
- (void)_setLocalOfferWithSdp:(RTCSessionDescription *)sdp{
    [self.pc setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
        
    }];
//    创建Offer 发送消息
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
        mdict[@"type"] = @"offer";
        mdict[@"sdp"] = sdp.sdp;
        
        NSDictionary *dict = [NSDictionary dictionaryWithDictionary:mdict];
        
        [[SocketIOManager shareManager] sendMessage:dict toRoom:self.roomNo response:^(id  _Nonnull data) {
            
        }];
        
        
    });
}

#pragma mark -----WebRTC内容---响应--

- (void)_getAnswerWtihMessage:(NSDictionary *)dict{
    NSString *remoteAnswerSdp = dict[@"sdp"];
    RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeAnswer sdp:remoteAnswerSdp];
    
    [self.pc setRemoteDescription:remoteSdp completionHandler:^(NSError * _Nullable error) {
        
    }];
}

- (void)_getOfferWtihMessage:(NSDictionary *)dict{
    NSString *remoteAnswerSdp = dict[@"sdp"];
    WeakSelf
    RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeOffer sdp:remoteAnswerSdp];
    [self.pc setRemoteDescription:remoteSdp completionHandler:^(NSError * _Nullable error) {
        if (!error) {
            [weakSelf _getAnswer];
        }
    }];
}

- (void)_getAnswer{
    WeakSelf
    [self.pc answerForConstraints:self.constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (!error) {
            [weakSelf.pc setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
//                响应SDP
                NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
                      mdict[@"type"] = @"answer";
                      mdict[@"sdp"] = sdp.sdp;
                      
                      NSDictionary *dict = [NSDictionary dictionaryWithDictionary:mdict];
                      
                      [[SocketIOManager shareManager] sendMessage:dict toRoom:self.roomNo response:^(id  _Nonnull data) {
                          
                      }];
                
            }];
        }
        
    }];
}

- (void)_getCandidateWithData:(NSDictionary *)dict{
    WeakSelf
    RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:dict[@"candidate"] sdpMLineIndex:[NSString stringWithFormat:@"%@",dict[@"label"]].intValue sdpMid:dict[@"id"]];
    
    [weakSelf.pc addIceCandidate:candidate];
}


#pragma mark -----渲染协议方法-----
- (void)videoView:(id<RTCVideoRenderer>)videoView didChangeVideoSize:(CGSize)size{
    
    
    if (videoView == self.remoteView) {
        if (size.width > size.height) {
            CGFloat width =  [UIScreen mainScreen].bounds.size.width;
            self.remoteView.frame = CGRectMake(0, 0, width, width * size.height/size.width);
            self.remoteView.center = self.view.center;
        } else {
            CGFloat height =  [UIScreen mainScreen].bounds.size.height;
           self.remoteView.frame = CGRectMake(0, 0, height*size.width/size.height ,  height);
           self.remoteView.center = self.view.center;
        }
        
    }
}


#pragma mark -----PeerConnection----
- (RTCPeerConnection *)pc{
    if (!_pc) {
        
        RTCIceServer *ice = [[RTCIceServer alloc] initWithURLStrings:@[@"turn:stun.varsiri.com:3478"] username:@"shawn" credential:@"850427"];
        
        RTCConfiguration *conf = [[RTCConfiguration alloc] init];
        [conf setIceServers:@[ice]];
        
        _pc = [self.factory peerConnectionWithConfiguration:conf constraints:self.constraints delegate:self];
        
//        [_pc addTransceiverOfType:RTCRtpMediaTypeVideo];
        
    }
    return _pc;
}




- (void)captureLocalMedia{
   

    //1.创建1个source
    RTCAudioSource *audioSource = [self.factory audioSourceWithConstraints:self.constraints];
    //2.创建trace（实际是source的一层封装）
    self.audioTrace = [self.factory audioTrackWithSource:audioSource trackId:@"ARDAMSa0"];
    
    NSArray<AVCaptureDevice *>*captureDevices = [RTCCameraVideoCapturer captureDevices];
    
    AVCaptureDevicePosition position = AVCaptureDevicePositionFront;
    AVCaptureDevice *device = captureDevices[0];
    for (AVCaptureDevice *obj in captureDevices) {
        if (obj.position == position) {
            device = obj;
            break;
        }
    }
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusNotDetermined) {
        
        return;
    }
    
    if (device) {
        
        //处理获取的视频数据代理
        RTCVideoSource *vedioSource = [self.factory videoSource];
        
        _capture = [[RTCCameraVideoCapturer alloc] initWithDelegate:vedioSource];
        
        AVCaptureDeviceFormat *format = [[RTCCameraVideoCapturer supportedFormatsForDevice:device] lastObject];
        
        CGFloat fps = [[format videoSupportedFrameRateRanges] firstObject].maxFrameRate;
        
        self.videoTrace = [self.factory videoTrackWithSource:vedioSource trackId:@"ARDAMSv0"];
        
//        关键显示的这一行（在内部还是通过source获取了数据，显示出来）
        self.localView.captureSession = self.capture.captureSession;
        
//        addStream
        [self.capture startCaptureWithDevice:device format:format fps:fps];
        
        [self _setSoketIO];
    }
    
}

- (void)_setSoketIO{
    
    WeakSelf
      SocketIOManager *socketM = [SocketIOManager shareManager];
    __block SocketIOManager * w_socket = socketM;
    //    链接服务器
        [socketM connectToServer:self.serverAddress response:^(id  _Nonnull data) {
    //        进入房间
            [w_socket joinRoomWithRoomNo:weakSelf.roomNo response:^(id  _Nonnull data) {
    //            穿件链接
                        NSArray <NSString *> *mediaStreamLables = @[@"ARDAMS"];
                //        添加视频Stream
                        [weakSelf.pc addTrack:self.videoTrace streamIds:mediaStreamLables];
                        [weakSelf.pc addTrack:self.audioTrace streamIds:mediaStreamLables];
            }];
        }];
        
        [socketM setAnswerAck:^(K_Message_Type msgType, id  _Nonnull data) {
            switch (msgType) {
                case K_Message_Type_Offer:
                    [weakSelf _getOfferWtihMessage:data];
                    break;
                 case K_Message_Type_Answer:
                    [weakSelf _getAnswerWtihMessage:data];
                    break;
                case K_Message_Type_Candidate:
                    [weakSelf _getCandidateWithData:data];
                break;
                default:
                    break;
            }
        }];
    //    满人了
        [socketM setRoomFullAck:^(id  _Nonnull data) {
            
        }];
    //其它人登陆了
        [socketM setOtherJoinAck:^(id  _Nonnull data) {
            
    //        1.媒体协商开始
            [weakSelf _otherJoin];
        }];
    
    [socketM setLeaveAck:^(id  _Nonnull data) {
        
        [w_socket leaveRoomWithRoomNo:weakSelf.roomNo response:^(id  _Nonnull data) {
            
        }];
        [weakSelf.pc close];
        weakSelf.pc = nil;
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
}




- (RTCMediaConstraints *)constraints{
    if (!_constraints) {
         NSDictionary *mandatoryConstansts = @{};
        _constraints  = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstansts optionalConstraints:nil];
    }
    return _constraints;
}


- (RTCPeerConnectionFactory *)factory{
    if (!_factory) {
        
        [RTCPeerConnectionFactory initialize];
        //解码器工厂
        RTCDefaultVideoDecoderFactory *decoderFactory = [RTCDefaultVideoDecoderFactory new];
        //编码器工厂
        RTCDefaultVideoEncoderFactory *encoderFactory = [RTCDefaultVideoEncoderFactory new];
        NSArray *codecs = [encoderFactory supportedCodecs];
        [encoderFactory setPreferredCodec:codecs[2]];
        
        
        _factory = [[RTCPeerConnectionFactory alloc] initWithEncoderFactory:encoderFactory decoderFactory:decoderFactory];
    }
    return _factory;
}



#pragma mark -----peerConnection的协议方法----
/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didChangeSignalingState:(RTCSignalingState)stateChanged{
    
    
}
/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream{
    //收到远程流.RTCMediaStream这类中包含audioTracks, videoTracks.
    //拿到视频流. 这流需要使用RTCEAGLVideoView 这类来渲染.使用起来很简单. 但是记得
    //- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size; 这个回调
    //当改变尺寸时候会调用.调用时机为初始化调用一次.每次改变尺寸调用.比如说技巧问题的时候
    //可以使用代理发送到界面上.这也是真正意义上音视频打洞完成.
    
    //音频流不用拿到,直接播放就可以了
    dispatch_async(dispatch_get_main_queue(), ^{
 
        if (stream.videoTracks.count) {
            self.remoteTrack = stream.videoTracks[0];
            [self.remoteTrack addRenderer:self.remoteView];   //渲染
        }
    });

}

/** Called when a remote peer closes a stream.
 *  This is not called when RTCSdpSemanticsUnifiedPlan is specified.
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream{
    
    
    
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection{

    
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState{
    
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState{
    NSLog(@"----------------正在获取Ice的candidate--------");
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate{
     NSLog(@"----------------已获取Ice的candidate--------");
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
           mdict[@"type"] = @"candidate";
        mdict[@"label"] = @(candidate.sdpMLineIndex);
        mdict[@"id"] = candidate.sdpMid;
           mdict[@"candidate"] = candidate.sdp;
           NSDictionary *dict = [NSDictionary dictionaryWithDictionary:mdict];
           [[SocketIOManager shareManager] sendMessage:dict toRoom:self.roomNo response:^(id  _Nonnull data) {
               
           }];
}

/** Called any time the IceConnectionState changes following standardized
 * transition. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeStandardizedIceConnectionState:(RTCIceConnectionState)newState{
    
}

/** Called any time the PeerConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeConnectionState:(RTCPeerConnectionState)newState{
    
}


/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates{
    
}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel{
    
    
}
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didStartReceivingOnTransceiver:(RTCRtpTransceiver *)transceiver{
    NSLog(@"---------------->开始创建receiver");
}


//底层自己创建的recevier
/** Called when a receiver and its track are created. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
        didAddReceiver:(RTCRtpReceiver *)rtpReceiver
               streams:(NSArray<RTCMediaStream *> *)mediaStreams{
     NSLog(@"---------------->调用receiver-->%@",peerConnection.receivers);
    RTCMediaStreamTrack *track = rtpReceiver.track;
    if ([track.kind isEqualToString:kRTCMediaStreamTrackKindVideo]) {
        if (!self.remoteView) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            RTCVideoTrack *video = (RTCVideoTrack *)track;
            
            NSLog(@"---------------->调用receiver-source->%@",video.source);

        });
        
    }
}
/** Called when the receiver and its track are removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
     didRemoveReceiver:(RTCRtpReceiver *)rtpReceiver{
    
    
}
/** Called when the selected ICE candidate pair is changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didChangeLocalCandidate:(RTCIceCandidate *)local
            remoteCandidate:(RTCIceCandidate *)remote
             lastReceivedMs:(int)lastDataReceivedMs
          changeReason:(NSString *)reason{
    
    
}


/** Callback for I420 frames. Each plane is given as a texture. */
- (void)applyShadingForFrameWithWidth:(int)width
                               height:(int)height
                             rotation:(RTCVideoRotation)rotation
                               yPlane:(GLuint)yPlane
                               uPlane:(GLuint)uPlane
                               vPlane:(GLuint)vPlane{
    NSLog(@"------receiver---->%f------->%f",width,height);
}

/** Callback for NV12 frames. Each plane is given as a texture. */
- (void)applyShadingForFrameWithWidth:(int)width
                               height:(int)height
                             rotation:(RTCVideoRotation)rotation
                               yPlane:(GLuint)yPlane
                              uvPlane:(GLuint)uvPlane{
       NSLog(@"----receiver------>%f------->%f",width,height);
}

- (IBAction)buttonClick:(id)sender {
    WeakSelf
    [[SocketIOManager shareManager] leaveRoomWithRoomNo:self.roomNo response:^(id  _Nonnull data) {
       
    }];
    
     [weakSelf dismissViewControllerAnimated:YES completion:nil];
}




#pragma mark ----UI交互----
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
   
    UITouch *touch = [touches anyObject];
        CGPoint pt = [touch locationInView:self.view];
        //点击其他地方消失
        if (CGRectContainsPoint([self.localView frame], pt)) {
            //to-do
            WeakSelf
                 weakSelf.localView.center = pt;
     
           
            
        }
    
}

@end
