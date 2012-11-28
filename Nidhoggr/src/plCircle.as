package {
	import nape.phys.Body;
	
	import starling.display.Image;
	import starling.display.Sprite;
	
	public class plCircle extends Sprite {
		public function plCircle() {
			addChild(Image.fromBitmap(new Assets.gfxCircle()));
			this.pivotX = this.width >> 1;
			this.pivotY = this.height >> 1;
		}
	}
}