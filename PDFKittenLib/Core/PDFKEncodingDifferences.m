//
//  PDFKEncodingDifferences.m
//  PDFKitten
//
//  Created by Kolyvan on 29.06.13.
//  Copyright (c) 2013 Konstantin Bukreev. All rights reserved.
//

#import "PDFKEncodingDifferences.h"

@interface PDFKAdobeCharsetEntry : NSObject
@property (readwrite, nonatomic) NSUInteger stdCode;
@property (readwrite, nonatomic) NSUInteger macCode;
@property (readwrite, nonatomic) NSUInteger winCode;
@property (readwrite, nonatomic) NSUInteger pdfCode;
@end

@implementation PDFKAdobeCharsetEntry
@end

@implementation PDFKEncodingDifferences {
    
    NSMutableDictionary *_map;
}

- (id) initWithArray:(CGPDFArrayRef)array
{
    self = [super init];
    if (self) {
        
        _map = [[NSMutableDictionary alloc] init];
        
        NSUInteger cid = 0;
        const NSUInteger count = CGPDFArrayGetCount(array);
        for (NSUInteger i = 0; i < count; ++i) {
            
            CGPDFObjectRef pdfObject;
            if (CGPDFArrayGetObject(array, i, &pdfObject)) {

                const CGPDFObjectType objType = CGPDFObjectGetType(pdfObject);
                
                if (objType == kCGPDFObjectTypeInteger) {
                    
                    CGPDFInteger tmp;
                    if (CGPDFObjectGetValue(pdfObject, kCGPDFObjectTypeInteger, &tmp)) {
                        
                        cid = tmp;
                    }
                                        
                } else if (objType == kCGPDFObjectTypeName) {
                    
                    const char *name;
                    if (CGPDFObjectGetValue(pdfObject, kCGPDFObjectTypeName, &name) &&
                        (0 != strcmp(name,  ".notdef"))) {
                        
                        _map[@(cid)] = @(name);
                    }
                    
                    cid++;
                }
            }
        }        
    }
    return self;
}


+ (NSDictionary *) loadAdobeCharsetDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    NSString *path = [[NSBundle mainBundle] resourcePath];
    path = [path stringByAppendingPathComponent:@"adobe_charset"];
    NSError *error;
    NSString *charsets = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!charsets) {
        NSLog(@"unable load adobe_charsets from resource '%@', %@", path, error);
        return nil;
    }
    
    NSCharacterSet *separator = [NSCharacterSet whitespaceCharacterSet];
    NSArray *lines = [charsets componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        
        NSArray *fields = [line componentsSeparatedByCharactersInSet:separator];
        if (fields.count == 5) {

            NSString *name = fields[0];
            NSString *stdCode = fields[1];
            NSString *macCode = fields[2];
            NSString *winCode = fields[3];
            NSString *pdfCode = fields[4];
            
            PDFKAdobeCharsetEntry *entry = [[PDFKAdobeCharsetEntry alloc] init];
            entry.stdCode = [stdCode isEqualToString:@"-"] ? NSNotFound : [stdCode integerValue];
            entry.macCode = [macCode isEqualToString:@"-"] ? NSNotFound : [macCode integerValue];
            entry.winCode = [winCode isEqualToString:@"-"] ? NSNotFound : [winCode integerValue];
            entry.pdfCode = [pdfCode isEqualToString:@"-"] ? NSNotFound : [pdfCode integerValue];
            md[name] = entry;
            
        } else {
            
            NSLog(@"invalid line '%@' in adobe_charset", line);
        }
    }
    
    return [md copy];
}

+ (NSDictionary *) loadAdobeGlyphsDict
{
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    NSString *path = [[NSBundle mainBundle] resourcePath];
    path = [path stringByAppendingPathComponent:@"adobe_glyphs"];
    NSError *error;
    NSString *glyphs = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!glyphs) {
        NSLog(@"unable load adobe_glyphs from resource '%@', %@", path, error);
        return nil;
    }
    
    NSCharacterSet *separator = [NSCharacterSet characterSetWithCharactersInString:@";"];
    NSArray *lines = [glyphs componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        
        NSArray *fields = [line componentsSeparatedByCharactersInSet:separator];
        if (fields.count == 2) {
            
            NSString *name = fields[0];
            NSString *uniCode = fields[1];
            
            unsigned value;
            NSScanner* scanner = [NSScanner scannerWithString:uniCode];
            if ([scanner scanHexInt:&value]) {
                md[name] = @(value);
            }
            
        } else {
            
            NSLog(@"invalid line '%@' in abobe_glyphs", line);
        }
    }

    return [md copy];
}

+ (NSDictionary *) adobeCharset
{
    static NSDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [self loadAdobeCharsetDict];
    });
    return dict;
}

+ (NSDictionary *)adobeGlyphs
{
    static NSDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [self loadAdobeGlyphsDict];
    });
    return dict;
}

- (NSUInteger) mapCid:(unichar)cid
         withEncoding:(PDFKCharacterEncoding)encoding
{
    NSString *name = _map[@(cid)];
    if (name) {
    
        if (encoding == PDFKStandardEncoding ||
            encoding == PDFKMacRomanEncoding ||
            encoding == PDFKWinAnsiEncoding ||
            encoding == PDFKDocEncoding) {
            
            NSDictionary *dict = [PDFKEncodingDifferences adobeCharset];
            PDFKAdobeCharsetEntry *entry = dict[name];
            if (entry) {
                
                if (encoding == PDFKStandardEncoding)
                    return entry.stdCode;
                    
                if (encoding == PDFKMacRomanEncoding)
                    return entry.macCode;
                
                if (encoding == PDFKWinAnsiEncoding)
                    return entry.winCode;
                
                if (encoding == PDFKDocEncoding)
                    return entry.pdfCode;
            }
            
        }
        
        NSDictionary *dict = [PDFKEncodingDifferences adobeGlyphs];
        NSNumber *uniCode = dict[name];
        if (uniCode) {
            return [uniCode unsignedIntegerValue];
        }
        
    }
    
    return NSNotFound;
}

- (NSUInteger) cidForName:(NSString *)name
{
    __block NSUInteger cid = NSNotFound;
    [_map enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSString *val, BOOL *stop) {
        
        if ([val isEqualToString:name]) {
            cid = key.unsignedIntegerValue;
            *stop = YES;
        }
        
    }];
    return cid;
}

- (NSUInteger)cidCharacter:(unichar)unicode
              withEncoding:(PDFKCharacterEncoding)encoding
{
    __block NSString *name = nil;
    
    if (encoding == PDFKStandardEncoding ||
        encoding == PDFKMacRomanEncoding ||
        encoding == PDFKWinAnsiEncoding ||
        encoding == PDFKDocEncoding) {
        
        NSDictionary *dict = [PDFKEncodingDifferences adobeCharset];
        
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, PDFKAdobeCharsetEntry *val, BOOL *stop) {
            
            if ((encoding == PDFKStandardEncoding && val.stdCode == unicode) ||
                (encoding == PDFKMacRomanEncoding && val.macCode == unicode) ||
                (encoding == PDFKWinAnsiEncoding && val.winCode == unicode) ||
                (encoding == PDFKDocEncoding && val.pdfCode == unicode)) {
                
                name = [key copy];
                *stop = YES;
            } 
        }];                
        
    } else {
        
        NSDictionary *dict = [PDFKEncodingDifferences adobeGlyphs];
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *val, BOOL *stop) {
            
            if (val.unsignedIntegerValue == unicode) {
               
                name = [key copy];
                *stop = YES;
            }
        }];
    }
    
    if (name) {        
        return [self cidForName:name];
    }
    return NSNotFound;
}

@end
