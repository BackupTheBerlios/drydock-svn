/*
	DDNormalSet.h
	Dry Dock for Oolite
	$Id$
	
	Copyright © 2006 Jens Ayton
	
	Normals in Dry Dock are stored as indices into an array. This class assists in building such
	an array while avoiding duplication. Now implemented as a subclass of DDVertexSet; the only
	difference is that DDNormalSet normalises its vectors.

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the “Software”), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all copies or
	substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "DDVertexSet.h"


@interface DDNormalSet: DDVertexSet

// Normalize() and CleanZeros() will be called on the vector by the DDNormalSet.
- (DDMeshIndex)indexForVector:(Vector)inVector;

@end
