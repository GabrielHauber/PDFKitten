#import "PDFScanner.h"
#import "PDFStringDetector.h"
#import "PDFFontCollection.h"
#import "PDFRenderingState.h"
#import "PDFSelection.h"
#import "RenderingStateStack.h"
#import "SimpleFont.h"

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

@interface PDFStringDetectorBBox : PDFStringDetector
@property (readonly, nonatomic) CGRect result;
@end

@interface PDFScanner() <PDFStringDetectorDelegate>
@property (nonatomic, weak, readonly) PDFRenderingState *renderingState;
@property (nonatomic, strong) RenderingStateStack *renderingStateStack;
@property (nonatomic, strong) PDFStringDetector *stringDetector;

@property (nonatomic, strong) NSMutableString *content;
@property (nonatomic, strong) NSMutableArray *selections;

@end

@implementation PDFScanner  {
	CGPDFPageRef pdfPage;
    PDFSelection *possibleSelection;
}

+ (PDFScanner *)scannerWithPage:(CGPDFPageRef)page {
	return [[PDFScanner alloc] initWithPage:page];
}

- (id)initWithPage:(CGPDFPageRef)page {
	if (self = [super init]) {
		pdfPage = page;
		self.fontCollection = [self fontCollectionWithPage:pdfPage];
		self.selections = [NSMutableArray array];
	}
	
	return self;
}

- (NSArray *)select:(NSString *)keyword {

    self.content = [NSMutableString string];
	self.stringDetector = [PDFStringDetector detectorWithKeyword:keyword delegate:self];
	[self.selections removeAllObjects];
    self.renderingStateStack = [RenderingStateStack stack];
    
 	CGPDFOperatorTableRef operatorTable = [self newOperatorTable];
	CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(pdfPage);
	CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, operatorTable, (__bridge void *)(self));
	CGPDFScannerScan(scanner);
	
	CGPDFScannerRelease(scanner);
	CGPDFContentStreamRelease(contentStream);
	CGPDFOperatorTableRelease(operatorTable);

    //NSLog(@"found %d for %@", self.selections.count, keyword);
    //NSLog(@"content:%@", self.content);
	
    self.stringDetector.delegate = nil;
    self.stringDetector = nil;
    
	return self.selections;
}

- (NSString *)scanText {
    
    self.content = [NSMutableString string];
    
    self.renderingStateStack = [RenderingStateStack stack];
    
 	CGPDFOperatorTableRef operatorTable = [self newOperatorTable];
	CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(pdfPage);
	CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, operatorTable, (__bridge void *)(self));
	CGPDFScannerScan(scanner);
	
	CGPDFScannerRelease(scanner);
	CGPDFContentStreamRelease(contentStream);
	CGPDFOperatorTableRelease(operatorTable);
    
	return [NSString stringWithString:_content];
}

- (CGRect)boundingBox
{
    self.content = nil;
	[self.selections removeAllObjects];
    
    PDFStringDetectorBBox *pdfBBOX = [[PDFStringDetectorBBox alloc] initWithKeyword:nil];
    
    self.stringDetector = pdfBBOX;
	self.stringDetector.delegate = self;
	
    self.renderingStateStack = [RenderingStateStack stack];
        
 	CGPDFOperatorTableRef operatorTable = [self newOperatorTable];
	CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(pdfPage);
	CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, operatorTable, (__bridge void *)(self));
	CGPDFScannerScan(scanner);
	
	CGPDFScannerRelease(scanner);
	CGPDFContentStreamRelease(contentStream);
	CGPDFOperatorTableRelease(operatorTable);
    
    self.stringDetector.delegate = nil;
    self.stringDetector = nil;
        
    const CGRect result = pdfBBOX.result;
    
    return result;
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
- (PDFFontCollection *)fontCollectionWithPage:(CGPDFPageRef)page {
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

	PDFFontCollection *collection = [[PDFFontCollection alloc] initWithFontDictionary:fonts];
	return collection;
}

- (void)detector:(PDFStringDetector *)detector didScanCharacter:(unichar)cid {
    
    PDFFont *font = self.renderingState.font;
    
    CGFloat width = [font widthOfCharacter:cid withFontSize:self.renderingState.fontSize];
    width /= 1000;
    width += self.renderingState.characterSpacing;
    
	[self.renderingState translateTextPosition:CGSizeMake(width, 0)];
}

- (void)detectorDidStartMatching:(PDFStringDetector *)detector {
    
    possibleSelection = [PDFSelection selectionWithState:self.renderingState];
    possibleSelection.foundLocation = self.content.length;
}

- (void)detectorFoundString:(PDFStringDetector *)detector {
    if (possibleSelection) {
	    possibleSelection.finalState = self.renderingState;
        [self.selections addObject:possibleSelection];
        possibleSelection = nil;
    }
}

- (PDFRenderingState *)renderingState {
	return [self.renderingStateStack topRenderingState];
}

@end

///


static BOOL isSpace(float width, PDFScanner *scanner) {
	return abs(width) >= scanner.renderingState.widthOfSpace;
}

void didScanSpace(float value, void *info) {
	PDFScanner *scanner = (__bridge PDFScanner *) info;
    float width = [scanner.renderingState convertToUserSpace:value];
    [scanner.renderingState translateTextPosition:CGSizeMake(-width, 0)];
    if (isSpace(value, scanner)) {
        
        [scanner.content appendString:@" "];
        //[scanner.stringDetector reset];
    }
}

void didScanString(CGPDFStringRef pdfString, void *info) {
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	PDFStringDetector *stringDetector = scanner.stringDetector;
	PDFFont *font = scanner.renderingState.font;
    
    [font enumeratePDFStringCharacters:pdfString usingBlock:^(NSUInteger cid, NSString *unicode) {
        if (unicode) {
            [stringDetector appendUnicodeString:unicode forCharacter:cid];
            [scanner.content appendString:unicode];
        }
    }];
}

void didScanNewLine(CGPDFScannerRef pdfScanner, PDFScanner *scanner, BOOL persistLeading) {
	CGPDFReal tx, ty;
	CGPDFScannerPopNumber(pdfScanner, &ty);
	CGPDFScannerPopNumber(pdfScanner, &tx);
	[scanner.renderingState newLineWithLeading:-ty indent:tx save:persistLeading];

    [scanner.content appendString:@" "];
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
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	[scanner.renderingState setHorizontalScaling:getNumber(pdfScanner)];
}

static void setTextLeading(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	[scanner.renderingState setLeadning:getNumber(pdfScanner)];
}

static void setFont(CGPDFScannerRef pdfScanner, void *info) {
	CGPDFReal fontSize;
	const char *fontName;
	CGPDFScannerPopNumber(pdfScanner, &fontSize);
	CGPDFScannerPopName(pdfScanner, &fontName);
	
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	PDFRenderingState *state = scanner.renderingState;
	PDFFont *font = [scanner.fontCollection fontNamed:@(fontName)];
	[state setFont:font];
	[state setFontSize:fontSize];
}

static void setTextRise(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	[scanner.renderingState setTextRise:getNumber(pdfScanner)];
}

static void setCharacterSpacing(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	[scanner.renderingState setCharacterSpacing:getNumber(pdfScanner)];
}

static void setWordSpacing(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	[scanner.renderingState setWordSpacing:getNumber(pdfScanner)];
}


#pragma mark Set position

static void newLine(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	[scanner.renderingState newLine];
}

static void newLineWithLeading(CGPDFScannerRef pdfScanner, void *info) {
	didScanNewLine(pdfScanner, (__bridge PDFScanner *) info, NO);
}

static void newLineSetLeading(CGPDFScannerRef pdfScanner, void *info) {
	didScanNewLine(pdfScanner, (__bridge PDFScanner *) info, YES);
}

static void newParagraph(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	[scanner.renderingState setTextMatrix:CGAffineTransformIdentity replaceLineMatrix:YES];

//    [scanner.content appendString:@"\n"];
}

static void setTextMatrix(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	[scanner.renderingState setTextMatrix:getTransform(pdfScanner) replaceLineMatrix:YES];
}


#pragma mark Print strings

static void printString(CGPDFScannerRef pdfScanner, void *info) {
	didScanString(getString(pdfScanner), info);
}

static void printStringNewLine(CGPDFScannerRef pdfScanner, void *info) {
	newLine(pdfScanner, info);
	printString(pdfScanner, info);
    
    PDFScanner *scanner = (__bridge PDFScanner *) info;
//    PDFStringDetector *stringDetector = scanner.stringDetector;
//    [stringDetector appendString:@"\n"];
    [scanner.content appendString:@"\n"];
    [scanner.stringDetector reset];
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
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	PDFRenderingState *state = [scanner.renderingState copy];
	[scanner.renderingStateStack pushRenderingState:state];
}

static void popRenderingState(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	[scanner.renderingStateStack popRenderingState];
}

/* Update CTM */
static void applyTransformation(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (__bridge PDFScanner *) info;
	PDFRenderingState *state = scanner.renderingState;
	state.ctm = CGAffineTransformConcat(getTransform(pdfScanner), state.ctm);
}


#pragma mark - PDFStringDetectorBBox

@implementation PDFStringDetectorBBox {
    
    BOOL _resultIsValid;
}

- (NSString *)appendString:(NSString *)inputString
{    
    PDFScanner *scanner = self.delegate;
    PDFSelection *selection = [PDFSelection selectionWithState:scanner.renderingState];
    
    int position = 0;
    while (position < inputString.length) {
        
		unichar inputCharacter = [inputString characterAtIndex:position];
		[scanner detector:self didScanCharacter:inputCharacter];
        ++position;        
    }
    
    selection.finalState = scanner.renderingState;
    const CGRect bbox = CGRectApplyAffineTransform(selection.frame, selection.transform);
    if (_resultIsValid) {
        
        _result = CGRectUnion(bbox, _result);
        
    } else {
        
        _resultIsValid = YES;
        _result = bbox;
    }
        
    return inputString;
}
@end
