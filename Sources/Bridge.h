#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
BOOL FBAvailable(void);
id _Nullable FBHide(NSArray<NSString *> *allowed, NSArray<NSNumber *> *systemItems, void (^completion)(NSError * _Nullable));
void FBRestore(id assertion);
NS_ASSUME_NONNULL_END
