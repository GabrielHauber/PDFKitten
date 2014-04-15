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
		_textMatrix = CGAffineTransformIdentity;
		_lineMatrix = CGAffineTransformIdentity;
        _ctm = CGAffineTransformIdentity;
		_horizontalScaling = 1.0;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	PDFKRenderingState *copy = [[PDFKRenderingState alloc] init];
	copy->_lineMatrix = _lineMatrix;
	copy->_textMatrix = _textMatrix;
	copy.leading = _leading;
	copy.wordSpacing = _wordSpacing;
	copy.characterSpacing = _characterSpacing;
	copy.horizontalScaling = _horizontalScaling;
	copy.textRise = _textRise;
	copy.font = _font;
	copy.fontSize = _fontSize;
	copy.ctm = _ctm;
    copy->_cachedWidthOfSpace = _cachedWidthOfSpace;
	return copy;
}

/* Set the text matrix, and optionally the line matrix */
- (void)setTextMatrix:(CGAffineTransform)matrix replaceLineMatrix:(BOOL)replace
{
	_textMatrix = matrix;

	if (replace)
		_lineMatrix = matrix;
}

/* Moves the text cursor forward */
- (void)translateTextPosition:(CGSize)size
{
	_textMatrix = CGAffineTransformTranslate(_textMatrix, size.width, size.height);
}

/* Move to start of next line, with custom line height and relative indent */
- (void)newLineWithLeading:(CGFloat)leading indent:(CGFloat)indent save:(BOOL)save
{
	CGAffineTransform t = CGAffineTransformTranslate(_lineMatrix, indent, -leading);
	[self setTextMatrix:t replaceLineMatrix:YES];
	if (save)
	{
		_leading = leading;
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
	[self newLineWithLeading:_leading save:NO];
}

/* Convert value to user space */
- (CGFloat)convertToUserSpace:(CGFloat)value
{
	return value * (_fontSize / kGlyphSpaceScale);
}

/* Converts a size from text space to user space */
- (CGSize)convertSizeToUserSpace:(CGSize)size
{
	size.width = [self convertToUserSpace:size.width];
	size.height = [self convertToUserSpace:size.height];
	return size;
}

- (CGFloat) widthOfSpace
{   
    if (!_cachedWidthOfSpace) {
        
        _cachedWidthOfSpace = _font.widthOfSpace;
        
        if (!_cachedWidthOfSpace && _font.fontDescriptor) {
            
            _cachedWidthOfSpace = _font.fontDescriptor.missingWidth;
        }
        
        if (!_cachedWidthOfSpace && _font.fontDescriptor) {
            
            _cachedWidthOfSpace = _font.fontDescriptor.averageWidth;
        }
        
        if (!_cachedWidthOfSpace) {
            
            // find a minimum width
            
            for (NSNumber *number in _font.widths.allValues) {
                
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
    
    PDFKFontDescriptor *fontDescriptor = _font.fontDescriptor;
    
    CGRect result = fontDescriptor.bounds;
    
    result.origin.x = 0;
    result.origin.y = MAX(result.origin.y, CGRectGetMaxY(result) - fontDescriptor.ascent);
    result.size.height = MAX(result.size.height, fontDescriptor.ascent - fontDescriptor.descent);
    result.size.width = 0;
    
    CGFloat k = _fontSize / kGlyphSpaceScale;
    
    result.origin.y *= k;
    result.size.height *= k;
    
    result.origin = CGPointApplyAffineTransform(result.origin, CGAffineTransformConcat(_textMatrix, _ctm));
    
    return result;
}

@end
