#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(StepBleManager, RCTEventEmitter)
RCT_EXTERN_METHOD(startScan:(NSString *)serviceUUID charUUID:(NSString *)charUUID)
RCT_EXTERN_METHOD(stop)
@end