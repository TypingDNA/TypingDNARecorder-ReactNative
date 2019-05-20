#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNTypingdnarecorder, NSObject)

RCT_EXTERN_METHOD(initialize)
RCT_EXTERN_METHOD(start)
RCT_EXTERN_METHOD(stop)
RCT_EXTERN_METHOD(reset)
RCT_EXTERN_METHOD(addTarget: (NSString *) targetId)
RCT_EXTERN_METHOD(removeTarget: (NSString *) targetId)
RCT_EXTERN_METHOD(getTypingPattern: (NSInteger *) type length: (NSInteger* ) length text: (NSString *) text textId: (NSInteger *) textId target: (NSString *) target caseSensitive: (BOOL) caseSensitive callback: (RCTResponseSenderBlock) callback)

@end
