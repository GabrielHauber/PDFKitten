#import "PDFKRenderingState.h"

#define kGlyphSpaceScale 1000

@implementation PDFKRenderingState {
    CGFloat _cachedWidthOfSpace;
}

- (id)init
{
    if ((self = [super init]))
	{
		// Default values
		self.textMatrix = CGAffineTransformIdentity;
		self.lineMatrix = CGAffineTransformIdentity;
        self.ctm = CGAffineTransformIdentity;
		self.horizontalScaling = 1.0;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	PDFKRenderingState *copy = [[PDFKRenderingState alloc] init];
	copy.lineMatrix = self.lineMatrix;
	copy.textMatrix = self.textMatrix;
	copy.leadning = self.leadning;
	copy.wordSpacing = self.wordSpacing;
	copy.characterSpacing = self.characterSpacing;
	copy.horizontalScaling = self.horizontalScaling;
	copy.textRise = self.textRise;
	copy.font = self.font;
	copy.fontSize = self.fontSize;
	copy.ctm = self.ctm;
    copy->_cachedWidthOfSpace = _cachedWidthOfSpace;
	return copy;
}

/* Set the text matrix, and optionally the line matrix */
- (void)setTextMatrix:(CGAffineTransform)matrix replaceLineMatrix:(BOOL)replace
{
	self.textMatrix = matrix;
	if (replace)
	{
		self.lineMatrix = matrix;
	}
}

/* Moves the text cursor forward */
- (void)translateTextPosition:(CGSize)size
{
	self.textMatrix = CGAffineTransformTranslate(self.textMatrix, size.width, size.height);
}

/* Move to start of next line, with custom line height and relative indent */
- (void)newLineWithLeading:(CGFloat)aLeading indent:(CGFloat)indent save:(BOOL)save
{
	CGAffineTransform t = CGAffineTransformTranslate(self.lineMatrix, indent, -aLeading);
	[self setTextMatrix:t replaceLineMatrix:YES];
	if (save)
	{
		self.leadning = aLeading;
	}
}

/* Transforms the rendering state to the start of the next line, with custom line height */
- (void)newLineWithLeading:(CGFloat)lineHeight save:(BOOL)save
{
	[self newLineWithLeading:lineHeight indent:0 save:save];
}

/* Transforms the rendering state to the start of the next line */
- (void)newLine
{
	[self newLineWithLeading:self.leadning save:NO];
}

/* Convert value to user space */
- (CGFloat)convertToUserSpace:(CGFloat)value
{
	return value * (self.fontSize / kGlyphSpaceScale);
}

/* Converts a size from text space to user space */
- (CGSize)convertSizeToUserSpace:(CGSize)aSize
{
	aSize.width = [self convertToUserSpace:aSize.width];
	aSize.height = [self convertToUserSpace:aSize.height];
	return aSize;
}

- (CGFloat) widthOfSpace
{   
    if (!_cachedWidthOfSpace) {
        
        _cachedWidthOfSpace = self.font.widthOfSpace;
        
        if (!_cachedWidthOfSpace && self.font.fontDescriptor) {
            
            _cachedWidthOfSpace = self.font.fontDescriptor.missingWidth;
        }
        
        if (!_cachedWidthOfSpace && self.font.fontDescriptor) {
            
            _cachedWidthOfSpace = self.font.fontDescriptor.averageWidth;
        }
        
        if (!_cachedWidthOfSpace) {
            
            // find a minimum width
            
            for (NSNumber *number in self.font.widths.allValues) {
                
                const CGFloat f = number.floatValue;
                if (f > 0 && (!_cachedWidthOfSpace || (f < _cachedWidthOfSpace))) {
                    _cachedWidthOfSpace = f;
                }
            }
            
            _cachedWidthOfSpace *= 0.75f;
        }
        
        if (!_cachedWidthOfSpace) {
            // TODO: find another way for detecting widthOfSpace in this case
            _cachedWidthOfSpace = 100.f;
        }
    }
    
    return _cachedWidthOfSpace;
}

- (CGRect)frame {
    
    PDFKFontDescriptor *fontDescriptor = self.font.fontDescriptor;
    
    CGRect result = fontDescriptor.bounds;
    
    result.origin.x = 0;
    result.origin.y = MAX(result.origin.y, CGRectGetMaxY(result) - fontDescriptor.ascent);
    result.size.height = MAX(result.size.height, fontDescriptor.ascent - fontDescriptor.descent);
    result.size.width = 0;
    
    CGFloat k = self.fontSize / kGlyphSpaceScale;
    
    result.origin.y *= k;
    result.size.height *= k;
    
    result.origin = CGPointApplyAffineTransform(result.origin, CGAffineTransformConcat(_textMatrix, _ctm));
    
    return result;
}

@end
