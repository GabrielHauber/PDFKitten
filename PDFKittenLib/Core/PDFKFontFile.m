#import "PDFKFontFile.h"

#define kHeaderLength 6

static NSDictionary *charactersByName = nil;

@implementation PDFKFontFile

- (id)initWithContentsOfURL:(NSURL *)url
{
	return [self initWithData:[NSData dataWithContentsOfURL:url]];
}

- (id)initWithData:(NSData *)someData
{
	if ((self = [super init]))
	{
		if (!someData)
		{
			return nil;
		}
		data = someData;
		NSScanner *scanner = [NSScanner scannerWithString:self.text];
		NSCharacterSet *delimiterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
		
		names = [NSMutableDictionary new];
		NSString *buffer;
		while (![scanner isAtEnd])
		{
			if (![scanner scanUpToCharactersFromSet:delimiterSet intoString:&buffer]) break;
			
			if ([buffer hasPrefix:@"%"])
			{
				[scanner scanUpToCharactersFromSet:newlineCharacterSet intoString:nil];
				continue;
			}
			
			if ([buffer isEqualToString:@"dup"])
			{
				int code;
				NSString *name;
				[scanner scanInt:&code];
				[scanner scanUpToCharactersFromSet:delimiterSet intoString:&name];
				if (name) names[@(code)] = name;
			}
		}
	}
	return self;
}

+ (unichar)characterByName:(NSString *)name
{
	if (!charactersByName)
	{
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									 

                                     @0xfb00, @"/ff",
                                     @0xfb01, @"/fi",
									 @0xfb02, @"/fl",
									 @0xfb04, @"/ffl",
									 
									 @0x0054, @"/T",
									 @0x0061, @"/a",
									 @0x0063, @"/c",
									 @0x0065, @"/e",
									 @0x0068, @"/h",
									 @0x0069, @"/i",
									 @0x006c, @"/l",
									 @0x006e, @"/n",
									 @0x006f, @"/o",
									 @0x0031, @"/one",
									 @0x002e, @"/period",
									 @0x0073, @"/s",
									 @0x0074, @"/t",
									 @0x0075, @"/u",
									 @0x0076, @"/v",
									 @0x0079, @"/y",
									 nil];
		
		charactersByName = dict;
	}
	
	return [charactersByName[name] intValue];
}

- (NSString *)stringWithCode:(int)code
{
	NSString *characterName = names[@(code)];
	unichar unicodeValue = [PDFKFontFile characterByName:characterName];
    if (!unicodeValue) unicodeValue = code;
	return [NSString stringWithFormat:@"%C", unicodeValue];
}

- (NSString *)text
{
	if (!text)
	{
		// ASCII segment length (little endian)
		unsigned char *bytes = (uint8_t *) [self.data bytes];
		if (bytes[0] == 0x80)
		{
			asciiTextLength = bytes[2] | bytes[3] << 8 | bytes[4] << 16 | bytes[5] << 24;
			NSData *textData = [[NSData alloc] initWithBytes:bytes+kHeaderLength length:asciiTextLength];
			text = [[NSString alloc] initWithData:textData encoding:NSASCIIStringEncoding];
		}
		else
		{
			text = [[NSString alloc] initWithData:self.data encoding:NSASCIIStringEncoding];
		}
	}
	return text;
}


@synthesize data, text, names;
@end
