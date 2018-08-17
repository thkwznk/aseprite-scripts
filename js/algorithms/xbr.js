/**
* 2xBR Filter
*
* Javascript implementation of the 2xBR filter.
*
* This is a rewrite of the previous 0.2.5 version, it outputs the same quality,
* however this version is about a magnitude **slower** than its predecessor. 
*
* Use this version if you want to learn how the algorithms works, as the code is 
* much more readable.
*
* @version 0.3.0
* @author Ascari <carlos.ascari.x@gmail.com>
*/
var xBR = (function () {
	"use strict"
	
	// 2xBR
	const SCALE = 2
	
	// Bit Masks used to extract color chanels from a 32bit pixel
	const REDMASK = 0x000000FF
	const GREENMASK = 0x0000FF00
	const BLUEMASK = 0x00FF0000
	const ALPHAMASK = 0xFF000000
	
	// Weights should emphasize luminance (Y), in order to work. Feel free to experiment.
	const Y_WEIGHT = 48
	const U_WEIGHT = 7
	const V_WEIGHT = 6
	
	/**
	* Container used to abstract a 32bit Integer into a RGBA Pixel.
	*
	* @class Pixel
	* @constructor
	* @param value {Number} Initial value
	*/
	function Pixel(value)
	{
		this.value = value | 0
		
		Object.defineProperty(this, 'red', {
			configurable: false,
			get: function(){
				return this.value & REDMASK
			}
		})
		Object.defineProperty(this, 'green', {
			configurable: false,
			get: function(){
				return (this.value & GREENMASK) >> 8
			}
		})
		Object.defineProperty(this, 'blue', {
			configurable: false,
			get: function(){
				return (this.value & BLUEMASK) >> 16
			}
		})
		Object.defineProperty(this, 'alpha', {
			configurable: false,
			get: function(){
				return (this.value & ALPHAMASK) >>24
			}
		})
	}
	
	/**
	* This is the window or `vision` of the xBR algorithm. The 10th index, the pixel
	* at the center holds the current pixel being scaled.
	*
	* @property matrix
	* @type Array
	*/
	var matrix = Object.freeze([
					 new Pixel(), new Pixel(), new Pixel(),
		new Pixel(), new Pixel(), new Pixel(), new Pixel(), new Pixel(),
		new Pixel(), new Pixel(), new Pixel(), new Pixel(), new Pixel(),
		new Pixel(), new Pixel(), new Pixel(), new Pixel(), new Pixel(),
					 new Pixel(), new Pixel(), new Pixel(),
	])
	
	// -----------------------------------------------------------------------------
	
	/**
	* Returns the absolute value of a number.
	*
	* **Note** 
	* `return (x >> 31) ^ x + (x >> 31)` also works (w/out a mask)
	*
	* @method abs
	* @param x {Number}
	* @return Number
	*/
	function abs(x)
	{
		var mask = x >> 31
		x = x ^ mask
		x = x - mask
		return x
	}
	
	/**
	* Calculates the weighted difference between two pixels.
	* 
	* These are the steps:
	*
	* 1. Finds absolute color diference between two pixels.
	* 2. Converts color difference into Y'UV, seperating color from light.
	* 3. Applies Y'UV thresholds, giving importance to luminance.
	* 
	* @method d
	* @param pixelA {Pixel}
	* @param pixelB {Pixel}
	* @return Number
	*/
	function d(pixelA, pixelB)
	{
		var r = abs(pixelA.red - pixelB.red)
		var b = abs(pixelA.blue - pixelB.blue)
		var g = abs(pixelA.green - pixelB.green)
		var y = r *  .299000 + g *  .587000 + b *  .114000
		var u = r * -.168736 + g * -.331264 + b *  .500000
		var v = r *  .500000 + g * -.418688 + b * -.081312
		var weight = (y * Y_WEIGHT) + (u * U_WEIGHT ) + (v * V_WEIGHT)
		return weight
	}
	
	/**
	* Blends two pixels together and retuns an new Pixel.
	*
	* **Note** This function ignores the alpha channel, if you wanted to work on 
	* images with transparancy, this is where you;d want to start.
	*
	* @method blend
	* @param pixelA {Pixel}
	* @param pixelB {Pixel}
	* @param alpha {Number}
	* @return Pixel
	*/
	function blend(pixelA, pixelB, alpha)
	{
		var reverseAlpha = 1 - alpha
		var r = (alpha * pixelB.red)   + (reverseAlpha * pixelA.red)
		var g = (alpha * pixelB.green) + (reverseAlpha * pixelA.green)
		var b = (alpha * pixelB.blue)  + (reverseAlpha * pixelA.blue)
		return new Pixel(r | g << 8 | b << 16 | -16777216)
	}
	
	// -----------------------------------------------------------------------------
	
	/**
	* Applies the xBR filter.
	*
	* @method execute
	* @param context {Canvas2dContext}
	* @param [srcX] {Number}
	* @param [srcY] {Number}
	* @param [srcW] {Number}
	* @param [srcH] {Number}
	* @return ImageData
	*/
	function execute(context, srcX, srcY, srcW, srcH) 
	{
		// Resolve arguments
		srcX = srcX | 0, 
		srcY = srcY | 0, 
		srcW = srcW || context.canvas.width,
		srcH = srcH || context.canvas.height
		
		// original
		var oImageData = context.getImageData(srcX, srcY, srcW, srcH)
		var oPixelView = new Uint32Array(oImageData.data.buffer)
		
		// scaled
		var scaledWidth = srcW * SCALE
		var scaledHeight = srcH * SCALE
		var sImageData = context.createImageData(scaledWidth, scaledHeight)
		var sPixelView = new Uint32Array(sImageData.data.buffer)
	
		/**
		* Converts x,y coordinates into an index pointing to the same pixel
		* in a Uint32Array.
		*
		* @method coord2index
		* @param x {Number}
		* @param y {Number}
		* @return Number
		*/
		function coord2index(x, y)
		{
			return srcW * y + x
		}
	
		/*
		* Main Loop; Algorithm is applied here
		*/
		for (var x = 0; x < srcW; ++x)
		{
			for (var y = 0; y < srcH; ++y)
			{
				/* Matrix: 10 is (0,0) i.e. current pixel.
					-2 | -1|  0| +1| +2 	(x)
				______________________________
				-2 |	    [ 0][ 1][ 2]
				-1 |	[ 3][ 4][ 5][ 6][ 7]
				 0 |	[ 8][ 9][10][11][12]
				+1 |	[13][14][15][16][17]
				+2 |	    [18][19][20]
				(y)|
				*/
				matrix[ 0].value = oPixelView[coord2index(x-1, y-2)]
				matrix[ 1].value = oPixelView[coord2index(  x, y-2)]
				matrix[ 2].value = oPixelView[coord2index(x+1, y-2)]
				matrix[ 3].value = oPixelView[coord2index(x-2, y-1)]
				matrix[ 4].value = oPixelView[coord2index(x-1, y-1)]
				matrix[ 5].value = oPixelView[coord2index(  x, y-1)]
				matrix[ 6].value = oPixelView[coord2index(x+1, y-1)]
				matrix[ 7].value = oPixelView[coord2index(x+2, y-1)]
				matrix[ 8].value = oPixelView[coord2index(x-2,   y)]
				matrix[ 9].value = oPixelView[coord2index(x-1,   y)]
				matrix[10].value = oPixelView[coord2index(  x,   y)]
				matrix[11].value = oPixelView[coord2index(x+1,   y)]
				matrix[12].value = oPixelView[coord2index(x+2,   y)]
				matrix[13].value = oPixelView[coord2index(x-2, y+1)]
				matrix[14].value = oPixelView[coord2index(x-1, y+1)]
				matrix[15].value = oPixelView[coord2index(  x, y+1)]
				matrix[16].value = oPixelView[coord2index(x+1, y+1)]
				matrix[17].value = oPixelView[coord2index(x+2, y+1)]
				matrix[18].value = oPixelView[coord2index(x-1, y+2)]
				matrix[19].value = oPixelView[coord2index(  x, y+2)]
				matrix[20].value = oPixelView[coord2index(x+1, y+2)]
				
				// Calculate color weights using 2 points in the matrix
				var d_10_9 	= d(matrix[10], matrix[9])
				var d_10_5 	= d(matrix[10], matrix[5])
				var d_10_11  	= d(matrix[10], matrix[11])
				var d_10_15 	= d(matrix[10], matrix[15])
				var d_10_14 	= d(matrix[10], matrix[14])
				var d_10_6 	= d(matrix[10], matrix[6])
				var d_4_8 	= d(matrix[4],  matrix[8])
				var d_4_1 	= d(matrix[4],  matrix[1])
				var d_9_5 	= d(matrix[9],  matrix[5])
				var d_9_15 	= d(matrix[9],  matrix[15])
				var d_9_3 	= d(matrix[9],  matrix[3])
				var d_5_11 	= d(matrix[5],  matrix[11])
				var d_5_0 	= d(matrix[5],  matrix[0])
				var d_10_4 	= d(matrix[10], matrix[4])
				var d_10_16 	= d(matrix[10], matrix[16])
				var d_6_12 	= d(matrix[6],  matrix[12])
				var d_6_1	= d(matrix[6],  matrix[1])
				var d_11_15 	= d(matrix[11], matrix[15])
				var d_11_7 	= d(matrix[11], matrix[7])
				var d_5_2 	= d(matrix[5],  matrix[2])
				var d_14_8 	= d(matrix[14], matrix[8])
				var d_14_19 	= d(matrix[14], matrix[19])
				var d_15_18 	= d(matrix[15], matrix[18])
				var d_9_13 	= d(matrix[9],  matrix[13])
				var d_16_12 	= d(matrix[16], matrix[12])
				var d_16_19 	= d(matrix[16], matrix[19])
				var d_15_20 	= d(matrix[15], matrix[20])
				var d_15_17 	= d(matrix[15], matrix[17])
	
				// Top Left Edge Detection Rule
				var a1 = (d_10_14 + d_10_6 + d_4_8  + d_4_1 + (4 * d_9_5))
				var b1 = ( d_9_15 +  d_9_3 + d_5_11 + d_5_0 + (4 * d_10_4))
				if (a1 < b1)
				{
					var new_pixel= (d_10_9 <= d_10_5) ? matrix[9] : matrix[5]
					var blended_pixel = blend(new_pixel, matrix[10], .5)
					sPixelView[((y * SCALE) * scaledWidth) + (x * SCALE)] = blended_pixel.value
				}
				else
				{
					sPixelView[((y * SCALE) * scaledWidth) + (x * SCALE)] = matrix[10].value
				}
	
				// Top Right Edge Detection Rule
				var a2 = (d_10_16 + d_10_4 + d_6_12 + d_6_1 + (4 * d_5_11))
				var b2 = (d_11_15 + d_11_7 +  d_9_5 + d_5_2 + (4 * d_10_6))
				if (a2 < b2)
				{
					var new_pixel= (d_10_5 <= d_10_11) ? matrix[5] : matrix[11]
					var blended_pixel = blend(new_pixel, matrix[10], .5)
					sPixelView[((y * SCALE) * scaledWidth) + (x * SCALE + 1)] = blended_pixel.value
				}
				else
				{
					sPixelView[((y * SCALE) * scaledWidth) + (x * SCALE + 1)] = matrix[10].value
				}
	
				// Bottom Left Edge Detection Rule
				var a3 = (d_10_4 + d_10_16 +  d_14_8 + d_14_19 + (4 * d_9_15))
				var b3 = ( d_9_5 +  d_9_13 + d_11_15 + d_15_18 + (4 * d_10_14))
				if (a3 < b3)
				{
					var new_pixel= (d_10_9 <= d_10_15) ? matrix[9] : matrix[15]
					var blended_pixel = blend(new_pixel, matrix[10], .5)
					var index = ((y * SCALE + 1) * scaledWidth) + (x * SCALE)
					sPixelView[index] = blended_pixel.value
				}
				else
				{
					var index = ((y * SCALE + 1) * scaledWidth) + (x * SCALE)
					sPixelView[index] = matrix[10].value
				}
	
				// Bottom Right Edge Detection Rule
				var a4 = (d_10_6 + d_10_14 + d_16_12 + d_16_19 + (4 * d_11_15))
				var b4 = (d_9_15 + d_15_20 + d_15_17 +  d_5_11 + (4 * d_10_16))
				if (a4 < b4)
				{
					var new_pixel= (d_10_11 <= d_10_15) ? matrix[11] : matrix[15]
					var blended_pixel = blend(new_pixel, matrix[10], .5)
					sPixelView[((y * SCALE + 1) * scaledWidth) + (x * SCALE + 1)] = blended_pixel.value
				}
				else
				{
					sPixelView[((y * SCALE + 1) * scaledWidth) + (x * SCALE + 1)] = matrix[10].value
				}
			}
		}
	
		return sImageData
	}
	
	return execute
	})();