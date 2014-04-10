#import <Foundation/Foundation.h>

@interface FontFile : NSObject {
	NSData *data;
	NSString *text;
	size_t asciiTextLength;
	NSMutableDictionary *__weak names;
}

+ (unichar)characterByName:(NSString *)name;

- (id)initWithContentsOfURL:(NSURL *)url;

- (id)initWithData:(NSData *)data;

- (NSString *)stringWithCode:(int)code;

@property (nonatomic, readonly) NSString *text;
@property (nonatomic, readonly) NSData *data;
@property (nonatomic, weak, readonly) NSDictionary *names;
@end
