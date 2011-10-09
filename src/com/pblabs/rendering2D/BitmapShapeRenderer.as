package com.pblabs.rendering2D
{
	import com.pblabs.engine.PBUtil;
	import com.pblabs.engine.core.ObjectType;
	import com.pblabs.engine.debug.Logger;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class BitmapShapeRenderer extends SimpleShapeRenderer implements ICopyPixelsRenderer
	{
		static protected const zeroPoint:Point = new Point();

		protected var bitmap:Bitmap = new Bitmap();
		protected var _smoothing:Boolean = false;
		protected var _shape:Sprite = new Sprite();

		public function BitmapShapeRenderer()
		{
			super();
			smoothing = true;
			bitmap.pixelSnapping = PixelSnapping.AUTO;
			(_displayObject as Sprite).addChild(bitmap);	
			
			lineSize = 0;
			lineAlpha = 0;
		}
		
		public function isPixelPathActive(objectToScreen:Matrix):Boolean
		{
			// No rotation/scaling/translucency/blend modes
			return (objectToScreen.a == 1 && objectToScreen.b == 0 && objectToScreen.c == 0 && objectToScreen.d == 1 && alpha == 1 && blendMode == BlendMode.NORMAL );//&& (displayObject.filters.length == 0)
		}
		
		public function drawPixels(objectToScreen:Matrix, renderTarget:BitmapData):void
		{
			// Draw to the target.
			if (bitmap.bitmapData!=null){
				renderTarget.copyPixels(bitmap.bitmapData, bitmap.bitmapData.rect, objectToScreen.transformPoint(zeroPoint), null, null, true);
			}
		}

		override public function pointOccupied(worldPosition:Point, mask:ObjectType):Boolean
		{
			if(!bitmap || !bitmap.bitmapData || !scene)
				return false;
			
			worldPosition = worldPosition.subtract( scene.position );
			// Figure local position.
			var localPos:Point = transformWorldToObject(worldPosition);
			return bitmap.bitmapData.hitTest(zeroPoint, 0x01, localPos);
		}
		
		override public function updateTransform(updateProps:Boolean = false):void
		{
			if(!displayObject)
				return;
			
			if(updateProps)
				updateProperties();
			
			// If size is active, it always takes precedence over scale.
			var tmpScaleX:Number = _scale.x;
			var tmpScaleY:Number = _scale.y;
			if(_size && (_size.x > 0 || _size.y > 0))
			{
				var localDimensions:Rectangle = displayObject.getBounds(displayObject);
				tmpScaleX = _scale.x * (_size.x / localDimensions.width);
				tmpScaleY = _scale.y * (_size.y / localDimensions.height);
			}
			
			
			_transformMatrix.identity();
			_transformMatrix.scale(tmpScaleX, tmpScaleY);
			_transformMatrix.translate(-_registrationPoint.x * tmpScaleX, -_registrationPoint.y * tmpScaleY);
			_transformMatrix.rotate(PBUtil.getRadiansFromDegrees(_rotation) + _rotationOffset);
			_transformMatrix.translate(_position.x + _positionOffset.x, _position.y + _positionOffset.y);
			
			displayObject.transform.matrix = _transformMatrix;
			displayObject.alpha = _alpha;
			displayObject.blendMode = _blendMode;
			displayObject.visible = (alpha > 0);
			
			_transformDirty = false;
		}

		
		override public function redraw():void
		{
			// Get references.
			var s:Sprite = _shape;
			if(!s)
				throw new Error("displayObject null or not a Sprite!");
			var g:Graphics = s.graphics;
			
			// Don't forget to clear.
			g.clear();
			
			// Prep line/fill settings.
			g.lineStyle(lineSize, lineColor, lineAlpha);
			g.beginFill(fillColor, fillAlpha);
			
			// Draw one or both shapes.
			if(isSquare)
				g.drawRect(0, 0, (radius*2), (radius*2));

			if(isCircle){
				var radiansX : Number = 180 * (Math.PI/180);
				var radiansY : Number = -90 * (Math.PI/180);
				var x : int = radius * Math.cos(radiansX);
				var y : int = radius * Math.sin(radiansY);
				g.drawCircle(-x, -y, radius);
			}
			
			g.endFill();
			
			// Sanity check.
			if(!isCircle && !isSquare)
			{
				Logger.error(this, "redraw", "Neither square nor circle, what am I?");
			}               
			
			if(!bitmap)
				bitmap = new Bitmap();
			if(bitmap.bitmapData){
				bitmap.bitmapData.dispose();
				bitmap.bitmapData = null;
			}
			var bounds : Rectangle = s.getBounds( s );
			var m : Matrix = new Matrix();
			//_registrationPoint = new Point(-bounds.topLeft.x, -bounds.topLeft.y);
			bitmap.bitmapData = new BitmapData(bounds.width,bounds.height, true, 0x000000);
			bitmap.bitmapData.draw(s,m, s.transform.colorTransform, s.blendMode );
		}
		
		override public function set scale(value:Point):void
		{
			super.scale = value;
			redraw();
		}
		/**
		 * @see Bitmap.smoothing 
		 */
		[EditorData(ignore="true")]
		public function set smoothing(value:Boolean):void
		{
			_smoothing = value;
			bitmap.smoothing = value;
		}
		
		public function get smoothing():Boolean
		{
			return _smoothing;
		}
	}
}