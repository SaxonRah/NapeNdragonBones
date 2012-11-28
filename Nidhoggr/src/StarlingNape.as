package {
	import flash.display.Sprite;
	
	import net.hires.debug.Stats;
	
	import starling.core.Starling;
	
	import Main;
	
	public class StarlingNape extends Sprite {
		public function StarlingNape() {
			Starling.multitouchEnabled = true;
			var star:Starling = new Starling(Main, stage);
			star.simulateMultitouch = true;
			star.start();
			addChild(new Stats());
		}
	}
}