#import "PDFKPageScanner.h"
#import "PDFKStringDetector.h"
#import "PDFKFontCollection.h"
#import "PDFKRenderingState.h"
#import "PDFKSelection.h"
#import "PDFKRenderingStateStack.h"
#import "PDFKSimpleFont.h"

static void setHorizontalScale(CGPDFScannerRef pdfScanner, void *info);
static void setTextLeading(CGPDFScannerRef pdfScanner, void *info);
static void setFont(CGPDFScannerRef pdfScanner, void *info);
static void setTextRise(CGPDFScannerRef pdfScanner, void *info);
static void setCharacterSpacing(CGPDFScannerRef pdfScanner, void *info);
static void setWordSpacing(CGPDFScannerRef pdfScanner, void *info);
static void newLine(CGPDFScannerRef pdfScanner, void *info);
static void newLineWithLeading(CGPDFScannerRef pdfScanner, void *info);
static void newLineSetLeading(CGPDFScannerRef pdfScanner, void *info);
static void newParagraph(CGPDFScannerRef pdfScanner, void *info);
static void setTextMatrix(CGPDFScannerRef pdfScanner, void *info);
static void printString(CGPDFScannerRef pdfScanner, void *info);
static void printStringNewLine(CGPDFScannerRef scanner, void *info);
static void printStringNewLineSetSpacing(CGPDFScannerRef scanner, void *info);
static void printStringsAndSpaces(CGPDFScannerRef pdfScanner, void *info);
static void pushRenderingState(CGPDFScannerRef pdfScanner, void *info);
static void popRenderingState(CGPDFScannerRef pdfScanner, void *info);
static void applyTransformation(CGPDFScannerRef pdfScanner, void *info);


@interface PDFKPageScanner() <PDFKStringDetectorDelegate>
@end

@implementation PDFKPageScanner  {
	CGPDFPageRef _pdfPage;
    
    PDFKRenderingStateStack *_renderingStateStack;
}

- (instancetype)initWithPage:(CGPDFPageRef)page {
	if (self = [super init]) {
		_pdfPage = CGPDFPageRetain(page);
		_fontCollection = [self fontCollectionWithPage:_pdfPage];
	}
	
	return self;
}

- (void)dealloc {
    CGPDFPageRelease(_pdfPage);
}

- (void)scan {

    _renderingStateStack = [PDFKRenderingStateStack stack];
    
 	CGPDFOperatorTableRef operatorTable = [self newOperatorTable];
	CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(_pdfPage);
	CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, operatorTable, (__bridge void *)(self));
	CGPDFScannerScan(scanner);
	
	CGPDFScannerRelease(scanner);
	CGPDFContentStreamRelease(contentStream);
	CGPDFOperatorTableRelease(operatorTable);
}

- (CGPDFOperatorTableRef)newOperatorTable {
	CGPDFOperatorTableRef operatorTable = CGPDFOperatorTableCreate();

	// Text-showing operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tj", printString);
	CGPDFOperatorTableSetCallback(operatorTable, "\'", printStringNewLine);
	CGPDFOperatorTableSetCallback(operatorTable, "\"", printStringNewLineSetSpacing);
	CGPDFOperatorTableSetCallback(operatorTable, "TJ", printStringsAndSpaces);
	
	// Text-positioning operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tm", setTextMatrix);
	CGPDFOperatorTableSetCallback(operatorTable, "Td", newLineWithLeading);
	CGPDFOperatorTableSetCallback(operatorTable, "TD", newLineSetLeading);
	CGPDFOperatorTableSetCallback(operatorTable, "T*", newLine);
	
	// Text state operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tw", setWordSpacing);
	CGPDFOperatorTableSetCallback(operatorTable, "Tc", setCharacterSpacing);
	CGPDFOperatorTableSetCallback(operatorTable, "TL", setTextLeading);
	CGPDFOperatorTableSetCallback(operatorTable, "Tz", setHorizontalScale);
	CGPDFOperatorTableSetCallback(operatorTable, "Ts", setTextRise);
	CGPDFOperatorTableSetCallback(operatorTable, "Tf", setFont);
	
	// Graphics state operators
	CGPDFOperatorTableSetCallback(operatorTable, "cm", applyTransformation);
	CGPDFOperatorTableSetCallback(operatorTable, "q", pushRenderingState);
	CGPDFOperatorTableSetCallback(operatorTable, "Q", popRenderingState);
	
	CGPDFOperatorTableSetCallback(operatorTable, "BT", newParagraph);
	
	return operatorTable;
}

/* Create a font dictionary given a PDF page */
- (PDFKFontCollection *)fontCollectionWithPage:(CGPDFPageRef)page {
	CGPDFDictionaryRef dict = CGPDFPageGetDictionary(page);
	if (!dict) 	{
		NSLog(@"Scanner: fontCollectionWithPage: page dictionary missing");
		return nil;
	}
	
	CGPDFDictionaryRef resources;
	if (!CGPDFDictionaryGetDictionary(dict, "Resources", &resources)) {
		NSLog(@"Scanner: fontCollectionWithPage: page dictionary missing Resources dictionary");
		return nil;
	}

	CGPDFDictionaryRef fonts;
	if (!CGPDFDictionaryGetDictionary(resources, "Font", &fonts)) {
		return nil;
	}

	PDFKFontCollection *collection = [[PDFKFontCollection alloc] initWithFontDictionary:fonts];
	return collection;
}

- (void)didScanString:(NSString *)string {
    if ([_delegate respondsToSelector:@selector(scanner:didScanString:)]) 
        [_delegate scanner:self didScanString:string];
}

- (void)didTranslatePositionForString:(NSString *)string {
    if ([_delegate respondsToSelector:@selector(scanner:didUpdateRenderingStateForString:)]) {
        [_delegate scanner:self didUpdateRenderingStateForString:string];
    }
}

- (PDFKRenderingState *)renderingState {
	return [_renderingStateStack currentRenderingState];
}

- (void)pushRenderingState {
	[_renderingStateStack pushRenderingState];
}

- (void)popRenderingState {
    [_renderingStateStack popRenderingState];
}

@end


#pragma mark - PDFKPageTextScanner


@interface PDFKPageTextScanner () <PDFKScannerDelegate>
@end


@implementation PDFKPageTextScanner {
    __weak NSMutableString *_text;
}

- (instancetype)initWithPage:(CGPDFPageRef)page {
    self = [super init];
    if (self) {
        self.delegate = self;
    }
    return self;
}

- (NSString *)scanText {
    
    NSMutableString *text = [NSMutableString new];

    _text = text;

    [self scan];
    
	return [NSString stringWithString:text];
}


#pragma mark - PDFKScannerDelegate Methods

- (void)scanner:(PDFKPageScanner *)scanner didScanString:(NSString *)string {
    [_text appendString:string];
}

@end


#pragma mark - PDFKPageSelectionsScanner


@interface PDFKPageSelectionsScanner () <PDFKScannerDelegate>
@end


@implementation PDFKPageSelectionsScanner {
    NSUInteger _location;
    
    NSMutableArray *_selections;
    PDFKSelection *_possibleSelection;
    PDFKSelection *_foundSelection;
    
    PDFKStringDetector *_stringDetector;
}

- (instancetype)initWithPage:(CGPDFPageRef)page {
    self = [super initWithPage:page];
    if (self) {
        self.delegate = self;
    }
    return self;
}

- (NSArray *)scanSelectionsMatchingString:(NSString *)seachString {
    
    _location = 0;
    
    NSMutableArray *selections = [NSMutableArray new];
    _selections = selections;
    
	_stringDetector = [PDFKStringDetector detectorWithKeyword:seachString delegate:self];

    [self scan];
    
    _stringDetector = nil;
    
	return [NSArray arrayWithArray:selections];
}


#pragma mark - PDFKScannerDelegate Methods

- (void)scanner:(PDFKPageScanner *)scanner didScanString:(NSString *)string {
    
    [_stringDetector appendUnicodeString:string];
    
    _location += string.length;
}

- (void)scanner:(PDFKPageScanner *)scanner didUpdateRenderingStateForString:(NSString *)string {

    if (_foundSelection) {

        _foundSelection.finalState = self.renderingState;
        
        [_selections addObject:_foundSelection];
        
        _foundSelection = nil;
    }
}


#pragma mark - PDFKStringDetectorDelegate Methods

- (void)detectorDidStartMatching:(PDFKStringDetector *)detector {
    
    _possibleSelection = [PDFKSelection selectionWithState:self.renderingState];
    _possibleSelection.foundLocation = _location;
}

- (void)detectorFoundString:(PDFKStringDetector *)detector {
    
    if (_possibleSelection) {
        _foundSelection = _possibleSelection;
        _possibleSelection = nil;
    }
}

@end


@interface PDFKPageBoundingBoxScanner () <PDFKScannerDelegate>
@end


@implementation PDFKPageBoundingBoxScanner {
    CGRect _result;
}

- (instancetype)initWithPage:(CGPDFPageRef)page {
    self = [super initWithPage:page];
    if (self) {
        self.delegate = self;
    }
    return self;
}

- (CGRect)scanBoundingBox {
    
    _result = CGRectNull;

	[self scan];
    
    return _result;
}


#pragma mark - PDFKScannerDelegate Methods

- (void)scanner:(PDFKPageScanner *)scanner didScanString:(NSString *)string {
    _result = CGRectUnion(_result, self.renderingState.frame);
}

- (void)scanner:(PDFKPageScanner *)scanner didUpdateRenderingStateForString:(NSString *)string {
    _result = CGRectUnion(_result, self.renderingState.frame);
}

@end

///


static BOOL isSpace(float width, PDFKPageScanner *scanner) {
	return abs(width) >= scanner.renderingState.widthOfSpace;
}

void didScanSpace(float value, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
    float width = [scanner.renderingState convertToUserSpace:value];
    [scanner.renderingState translateTextPosition:CGSizeMake(-width, 0)];

    if (isSpace(value, scanner)) {
        
        [scanner didScanString:@" "];
        //[scanner.stringDetector reset];
    }
}

void didScanString(CGPDFStringRef pdfString, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
	PDFKFont *font = scanner.renderingState.font;
    
    [font enumeratePDFStringCharacters:pdfString usingBlock:^(NSUInteger cid, NSString *unicode) {
        if (unicode) {
            [scanner didScanString:unicode];

            PDFKFont *font = scanner.renderingState.font;
            
            CGFloat width = [font widthOfCharacter:cid withFontSize:scanner.renderingState.fontSize];
            width /= 1000;
            width += scanner.renderingState.characterSpacing;
            
            [scanner.renderingState translateTextPosition:CGSizeMake(width, 0)];
            
            [scanner didTranslatePositionForString:unicode];
        }
    }];
}

void didScanNewLine(CGPDFScannerRef pdfScanner, PDFKPageScanner *scanner, BOOL persistLeading) {
	CGPDFReal tx, ty;
	CGPDFScannerPopNumber(pdfScanner, &ty);
	CGPDFScannerPopNumber(pdfScanner, &tx);
	[scanner.renderingState newLineWithLeading:-ty indent:tx save:persistLeading];

    [scanner didScanString:@" "];
}

CGPDFStringRef getString(CGPDFScannerRef pdfScanner) {
	CGPDFStringRef pdfString;
	CGPDFScannerPopString(pdfScanner, &pdfString);
	return pdfString;
}

CGPDFReal getNumber(CGPDFScannerRef pdfScanner) {
	CGPDFReal value;
	CGPDFScannerPopNumber(pdfScanner, &value);
	return value;
}

CGPDFArrayRef getArray(CGPDFScannerRef pdfScanner) {
	CGPDFArrayRef pdfArray;
	CGPDFScannerPopArray(pdfScanner, &pdfArray);
	return pdfArray;
}

CGPDFObjectRef getObject(CGPDFArrayRef pdfArray, int index) {
	CGPDFObjectRef pdfObject;
	CGPDFArrayGetObject(pdfArray, index, &pdfObject);
	return pdfObject;
}

CGPDFStringRef getStringValue(CGPDFObjectRef pdfObject) {
	CGPDFStringRef string;
	CGPDFObjectGetValue(pdfObject, kCGPDFObjectTypeString, &string);
	return string;
}

float getNumericalValue(CGPDFObjectRef pdfObject, CGPDFObjectType type) {
	if (type == kCGPDFObjectTypeReal) {
		CGPDFReal tx;
		CGPDFObjectGetValue(pdfObject, kCGPDFObjectTypeReal, &tx);
		return tx;
	}
	else if (type == kCGPDFObjectTypeInteger) {
		CGPDFInteger tx;
		CGPDFObjectGetValue(pdfObject, kCGPDFObjectTypeInteger, &tx);
		return tx;
	}
    
	return 0;
}

CGAffineTransform getTransform(CGPDFScannerRef pdfScanner) {
	CGAffineTransform transform;
	transform.ty = getNumber(pdfScanner);
	transform.tx = getNumber(pdfScanner);
	transform.d = getNumber(pdfScanner);
	transform.c = getNumber(pdfScanner);
	transform.b = getNumber(pdfScanner);
	transform.a = getNumber(pdfScanner);
	return transform;
}

#pragma mark Text parameters

static void setHorizontalScale(CGPDFScannerRef pdfScanner, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
	[scanner.renderingState setHorizontalScaling:getNumber(pdfScanner)];
}

static void setTextLeading(CGPDFScannerRef pdfScanner, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
	[scanner.renderingState setLeadning:getNumber(pdfScanner)];
}

static void setFont(CGPDFScannerRef pdfScanner, void *info) {
	CGPDFReal fontSize;
	const char *fontName;
	CGPDFScannerPopNumber(pdfScanner, &fontSize);
	CGPDFScannerPopName(pdfScanner, &fontName);
	
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
	PDFKRenderingState *state = scanner.renderingState;
	PDFKFont *font = [scanner.fontCollection fontNamed:@(fontName)];
	[state setFont:font];
	[state setFontSize:fontSize];
}

static void setTextRise(CGPDFScannerRef pdfScanner, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
	[scanner.renderingState setTextRise:getNumber(pdfScanner)];
}

static void setCharacterSpacing(CGPDFScannerRef pdfScanner, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
	[scanner.renderingState setCharacterSpacing:getNumber(pdfScanner)];
}

static void setWordSpacing(CGPDFScannerRef pdfScanner, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
	[scanner.renderingState setWordSpacing:getNumber(pdfScanner)];
}


#pragma mark Set position

static void newLine(CGPDFScannerRef pdfScanner, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
	[scanner.renderingState newLine];
}

static void newLineWithLeading(CGPDFScannerRef pdfScanner, void *info) {
	didScanNewLine(pdfScanner, (__bridge PDFKPageScanner *) info, NO);
}

static void newLineSetLeading(CGPDFScannerRef pdfScanner, void *info) {
	didScanNewLine(pdfScanner, (__bridge PDFKPageScanner *) info, YES);
}

static void newParagraph(CGPDFScannerRef pdfScanner, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
	[scanner.renderingState setTextMatrix:CGAffineTransformIdentity replaceLineMatrix:YES];

//    [scanner.content appendString:@"\n"];
}

static void setTextMatrix(CGPDFScannerRef pdfScanner, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
	[scanner.renderingState setTextMatrix:getTransform(pdfScanner) replaceLineMatrix:YES];
}


#pragma mark Print strings

static void printString(CGPDFScannerRef pdfScanner, void *info) {
	didScanString(getString(pdfScanner), info);
}

static void printStringNewLine(CGPDFScannerRef pdfScanner, void *info) {
	newLine(pdfScanner, info);
	printString(pdfScanner, info);
    
    PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
    [scanner didScanString:@"\n"];
}

static void printStringNewLineSetSpacing(CGPDFScannerRef scanner, void *info) {
	setWordSpacing(scanner, info);
	setCharacterSpacing(scanner, info);
	printStringNewLine(scanner, info);
}

static void printStringsAndSpaces(CGPDFScannerRef pdfScanner, void *info) {
	CGPDFArrayRef array = getArray(pdfScanner);
	for (int i = 0; i < CGPDFArrayGetCount(array); i++) {
		CGPDFObjectRef pdfObject = getObject(array, i);
		CGPDFObjectType valueType = CGPDFObjectGetType(pdfObject);
        
		if (valueType == kCGPDFObjectTypeString) {
			didScanString(getStringValue(pdfObject), info);
		}
		else {
			didScanSpace(getNumericalValue(pdfObject, valueType), info);
		}
	}
}


#pragma mark Graphics state operators

static void pushRenderingState(CGPDFScannerRef pdfScanner, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
    [scanner pushRenderingState];
}

static void popRenderingState(CGPDFScannerRef pdfScanner, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
    [scanner popRenderingState];
}

/* Update CTM */
static void applyTransformation(CGPDFScannerRef pdfScanner, void *info) {
	PDFKPageScanner *scanner = (__bridge PDFKPageScanner *) info;
	PDFKRenderingState *state = scanner.renderingState;
	state.ctm = CGAffineTransformConcat(getTransform(pdfScanner), state.ctm);
}

