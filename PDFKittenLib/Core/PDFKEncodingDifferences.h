//
//  PDFKEncodingDifferences.h
//  PDFKitten
//
//  Created by Kolyvan on 29.06.13.
//  Copyright (c) 2013 Konstantin Bukreev. All rights reserved.
//

#import "PDFKFont.h"

@interface PDFKEncodingDifferences : NSObject

- (id)initWithArray:(CGPDFArrayRef)array;

- (NSUInteger)mapCid:(unichar)cid withEncoding:(PDFKCharacterEncoding)encoding;

- (NSUInteger)cidForName:(NSString *)name;

- (NSUInteger)cidCharacter:(unichar)unicode withEncoding:(PDFKCharacterEncoding)encoding;

@end
