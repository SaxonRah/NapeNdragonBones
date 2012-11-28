package {
	import nape.phys.Body;
	
	import starling.display.Image;
	import starling.display.Sprite;
	
	public class plBox extends Sprite {
		public function plBox() {
			addChild(Image.fromBitmap(new Assets.gfxBox()));
			this.pivotX = this.width >> 1;
			this.pivotY = this.height >> 1;
		}
	}
}