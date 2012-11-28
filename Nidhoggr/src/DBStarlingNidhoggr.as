package {
//-----------------------------------------------------------------------------------------------------------------------Package / Imports
	import flash.display.Stage;
	import flash.display.Bitmap;
	import flash.geom.Point;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.AccelerometerEvent;
	import flash.sensors.Accelerometer;
	import nape.callbacks.CbEvent;
	
	import net.hires.debug.Stats;
	
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.TouchEvent;
	import starling.events.Touch;
	import starling.events.TouchPhase;
	import starling.events.KeyboardEvent;
	import starling.text.TextField;
	import starling.core.Starling;
	import starling.display.Stage;
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.factorys.StarlingFactory;
	import dragonBones.events.AnimationEvent;
	
	import nape.space.Space;
	import nape.constraint.PivotJoint;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyList;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Circle;
	import nape.shape.Polygon;
//------------------------------------------------------------------------------------------------------------------------------Class Dec / Vars	
	public class DBStarlingNidhoggr extends starling.display.Sprite {
		
		private var textField:TextField, textField2:TextField, textField3:TextField;
		private var left:Boolean;
		private var right:Boolean;
		private var isAttacking:Boolean = false;
		private var mouseX:Number = 0;
		private var mouseY:Number = 0;
		private var isJumping:Boolean;
		private var isSquat:Boolean;
		private var moveDir:int;
		private var face:int;
		private var weaponID:int = -1;
		private var speedX:Number = 5;
		private var speedY:Number = 0;
		private var nativeStage:flash.display.Stage = Starling.current.nativeStage;
		private var space:Space;
		private var hand:PivotJoint;
		
		public var factory:StarlingFactory;
		public var armature:Armature;
		public var armatureClip:Sprite;
		public var armatureBody:Body;
		public var cbevent:CbEvent;
		
		private static const GRAVITY_X:Number = 0;
		private static const GRAVITY_Y:Number = 5000;
		private static const STEP_TIME:Number = 0.01;
		private static const NUMBER_OF_BALLS:Number = 10;
		private static const BALL_Y:Number = Math.random() + 100;
		private static const BALL_RADIUS:Number = 32; // TODO make dynamic
		private static const BALL_ELASTICITY:Number = 1.5;
		private static const NUMBER_OF_BOXS:Number = 20;
		private static const BOX_Y:Number = Math.random() + 100;
		private static const BOX_RADIUS:Number = 32; // TODO make dynamic
		private static const BOX_ELASTICITY:Number = 1.5;
//-----------------------------------------------------------------------------------------------------------------------------Construct
		public function DBStarlingNidhoggr() {
			factory = new StarlingFactory();
			factory.parseData(new Assets.ResourcesData());
			factory.addEventListener(Event.COMPLETE, textureCompleteHandler);
		}
//--------------------------------------------------------------------------------------StarlingFactory-EventComplete / Listeners /  Flow Control
		private function textureCompleteHandler(e:Event):void {
			stage.addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrameHandler);
			addBackground();
			
			createSpace();
			createFloor();
			createHand();
			
			armature = factory.buildArmature("cyborg");
			armatureClip = armature.display as Sprite;
			armatureClip.x = 100;
			armatureClip.y = 50;
			
			armatureBody = new Body(BodyType.DYNAMIC, new Vec2(armatureClip.x, armatureClip.y));
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyEventHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyEventHandler);
			
			changeWeapon();
			
			textField = new TextField(700, 30, "Press W/A/S/D to move. Press Shift to switch weapons.", "Verdana", 16, 0, true);
			textField2 = new TextField(700, 30, "Move mouse to aim. Press Space to attack.", "Verdana", 16, 0, true);
			textField3 = new TextField(700, 30, "Soon to come, Better physics.", "Verdana", 16, 0, true);
			
			textField.color = 111111;
			textField2.color = 111111;
			textField3.color = 111111;
			
			textField.x = 75;
			textField2.x = 75;
			textField3.x = 75;
			textField.y = 5;
			textField2.y = 25;
			textField3.y = 45;
			
			addChild(textField);
			addChild(textField2);
			addChild(textField3);
			
			useAccelerometer();
			
			addBalls();
			addBoxs();
			createCharacter();
			addChild(armatureClip);
		
		}
//--------------------------------------------------------------------------------------------------------------------------KeyBoardEvents	
		private function onKeyEventHandler(e:KeyboardEvent):void {
			switch (e.keyCode) {
				case 37:
				case 65:
					left = e.type == KeyboardEvent.KEY_DOWN;
					updateMove(-1);
					break;
				case 39:
				case 68:
					right = e.type == KeyboardEvent.KEY_DOWN;
					updateMove(1);
					break;
				case 38:
				case 87:
					if (e.type == KeyboardEvent.KEY_DOWN) {
						jump();
					}
					break;
				case 83:
				case 40:
					squat(e.type == KeyboardEvent.KEY_DOWN);
					break;
				case 16:
					if (e.type == KeyboardEvent.KEY_UP) {
						changeWeapon();
					}
					break;
				case 32:
					attack(e.type == KeyboardEvent.KEY_UP);
					isAttacking = true;
			}
		}
//---------------------------------------------------------------------------------------------------------------------------------		
		private function onEnterFrameHandler(_e:EnterFrameEvent):void {
			hand.anchor1.setxy(nativeStage.mouseX, nativeStage.mouseY);
			//---nape
			space.step(STEP_TIME);
			//---nape
			if (stage && !stage.hasEventListener(TouchEvent.TOUCH)) {
				stage.addEventListener(TouchEvent.TOUCH, onMouseMoveHandler);
				space.step(STEP_TIME);
			}
			updateSpeed();
			updateCharFacing();
			armature.update();
		}
//---------------------------------------------------------------------------------------------------------------------------------		
		public function onMouseMoveHandler(_e:TouchEvent):void {
			var _p:Point = _e.getTouch(stage).getLocation(stage);
			var touch:Touch = _e.getTouch(stage);
			var mousePoint:Vec2 = new Vec2(_p.x, _p.y);
			var bodies:BodyList = space.bodiesUnderPoint(mousePoint);
			if (touch.phase == TouchPhase.HOVER) {
				mouseX = _p.x;
				mouseY = _p.y;
			}
			if (touch.phase == TouchPhase.BEGAN && TouchPhase.MOVED) {
				for (var i:int = 0; i < bodies.length; i++) {
					var b:Body = bodies.at(i);
					var body:Body = bodies.shift();
					hand.body2 = body;
					hand.anchor2 = body.worldToLocal(mousePoint);
					hand.active = true;
				}
			}
			if (touch.phase == TouchPhase.ENDED){
				hand.active = false;
			}
			if (touch.phase == TouchPhase.STATIONARY){
				hand.active = false;
			}
		}
//----------------------------------------------------------------------------------------------------------------------------DragonBones Movement		
		public function armatureMovementChangeHandler(e:AnimationEvent):void {
			switch (e.movementID) {
				case "stand":
					armature.removeEventListener(AnimationEvent.MOVEMENT_CHANGE, armatureMovementChangeHandler);
					updateMovement();
					break;
			}
		}
//---------------------------------------------------------------------------------------------------------------------------------		
		private function updateMove(_dir:int):void {
			if (left && right) {
				move(_dir);
			} else if (left) {
				move((armatureBody.position.x = armatureBody.position.x + _dir * speedX));
			} else if (right) {
				move((armatureBody.position.x = armatureBody.position.x + _dir * speedX));
			} else {
				move(0);
			}
		}
//---------------------------------------------------------------------------------------------------------------------------------		
		public function move(_dir:int):void {
			if (moveDir == _dir) {
				return;
			}
			moveDir = _dir;
			updateMovement();
		}
//---------------------------------------------------------------------------------------------------------------------------------		
		public function updateMovement():void {
			space.step(STEP_TIME);
			if (isJumping) {
				return;
			}
			if (isSquat) {
				armature.animation.gotoAndPlay("squat");
				return;
			}
			if (isAttacking) {
				return;
			}
			if (moveDir == 0) {
				armature.animation.gotoAndPlay("stand");
			} else {
				if (moveDir * face > 0) {
					armature.animation.gotoAndPlay("run");
				} else {
					
					armature.animation.gotoAndPlay("runBack");
				}
			}
		}
//---------------------------------------------------------------------------------------------------------------------------------		
		public function updateSpeed():void {
			space.step(STEP_TIME);
			if (isJumping) {
					armature.animation.gotoAndPlay("fall");
				//armatureBody.position.y = armatureBody.position.y - 10;
			}
		}
//---------------------------------------------------------------------------------------------------------------------------------		
		public function jump():void {
			if (isJumping) {
				return;
			}
			armatureBody.velocity = new Vec2(0, 1)
			armatureBody.position.y = armatureBody.position.y -10;
			isJumping = true;
			armature.animation.gotoAndPlay("jump");

		}
//---------------------------------------------------------------------------------------------------------------------------------		
		public function squat(_isDown:Boolean):void {
			if (isSquat == _isDown) {
				return;
			}
			isSquat = _isDown;
			updateMovement();
		}
//---------------------------------------------------------------------------------------------------------------------------------		
		public function attack(_isUp:Boolean):void {
			if (isAttacking == _isUp) {
				return;
			}
			var _armR:Bone = armature.getBone("armOutside");
			var _armL:Bone = armature.getBone("armInside");
			var _attackName:String = "weapon" + (weaponID + 1) + "a";
			_armR.childArmature.animation.gotoAndPlay(_attackName);
			_armL.childArmature.animation.gotoAndPlay(_attackName);
		}
//---------------------------------------------------------------------------------------------------------------------------------		
		public function changeWeapon():void {
			weaponID++;
			if (weaponID >= 4) {
				weaponID -= 4;
			}
			var _armR:Bone = armature.getBone("armOutside");
			var _armL:Bone = armature.getBone("armInside");
			var _movementName:String = "weapon" + (weaponID + 1);
			_armR.childArmature.animation.gotoAndPlay(_movementName);
			_armL.childArmature.animation.gotoAndPlay(_movementName);
		}
		
//----------------------------------------------------------------------------------------------------------------------Procedural Char Animation	
		public function updateCharFacing():void {
			var _armR:Bone = armature.getBone("armOutside");
			var _armL:Bone = armature.getBone("armInside");
			var _body:Bone = armature.getBone("body");
			var _chest:Bone = armature.getBone("chest");
			var _head:Bone = armature.getBone("head");
			var _r:Number;
			
			// Update facing if mouse is left or right
			face = mouseX > armatureClip.x ? 1 : -1;
			if (armatureClip.scaleX != face) {
				armatureClip.scaleX = face;
				updateMovement();
			}
			// ---------------------------------------------
			if (face > 0) {
				_r = Math.atan2(mouseY - armatureClip.y, mouseX - armatureClip.x);
			} else {
				_r = Math.PI - Math.atan2(mouseY - armatureClip.y, mouseX - armatureClip.x);
				if (_r > Math.PI) {
					_r -= Math.PI * 2;
				}
			}
			// ----------------------------------------Rotate bones dependant on mouse
			_body.node.rotation = _r * 0.25;
			_chest.node.rotation = _r * 0.25;
			if (_r > 0) {
				_head.node.rotation = _r * 0.2;
			} else {
				_head.node.rotation = _r * 0.4;
			}
			_armR.node.rotation = _r * 0.5;
			if (_r > 0) {
				_armL.node.rotation = _r * 0.8;
			} else {
				_armL.node.rotation = _r * 0.6;
			}
		}
		
//---------------------------------------------------------------------------------------------------------------------------------accelerometer		
		private function useAccelerometer():void {
			var accelerometer:Accelerometer = new Accelerometer();
			accelerometer.addEventListener(AccelerometerEvent.UPDATE, function(event:AccelerometerEvent):void {
					space.gravity = new Vec2(-event.accelerationX * 5000, GRAVITY_Y);
				});
		}
		
//---------------------------------------------------------------------------------------------------------------------------------Nape
//---------------------------------------------------------------------------------------------------------------------------------bg		
		private function addBackground():void {
			addChild(Image.fromBitmap(new Assets.gfxBg()));
		}
		
//---------------------------------------------------------------------------------------------------------------------------------space		
		private function createSpace():void {
			space = new Space(new Vec2(GRAVITY_X, GRAVITY_Y));
		}
		
//---------------------------------------------------------------------------------------------------------------------------------floor		
		private function createFloor():void {
			const floor:Body = new Body(BodyType.STATIC);
			//Ground
			floor.shapes.add(new Polygon(Polygon.rect(0, nativeStage.stageHeight, nativeStage.stageWidth, 64)));
			//Left Wall
			// take 64 from the x pos, since we have a body 64 wide and want it to be aligned with the stage
			floor.shapes.add(new Polygon(Polygon.rect(-64, 0, 64, stage.stageHeight)));
			//Right Wall
			floor.shapes.add(new Polygon(Polygon.rect(stage.stageWidth, 0, 64, stage.stageHeight)));
			//Ceiling
			// take 64 from the y pos, since we have a body 64 tall and want it to be aligned with the stage
			floor.shapes.add(new Polygon(Polygon.rect(0, -64, stage.stageWidth, 64)));
			floor.space = space;
		}
		
//---------------------------------------------------------------------------------------------------------------------------------hand		
		private function createHand():void {
			hand = new PivotJoint(space.world, null, new Vec2(), new Vec2());
			hand.active = false;
			hand.stiff = false;
			hand.space = space;
		}
		
//---------------------------------------------------------------------------------------------------------------------------------char	
		public function createCharacter():Body {
			//crazy magic numbers, if you can figure out what im not picking up, please fix this as its crazy voodoo magicka
			armatureBody.shapes.add(new Polygon(Polygon.rect((-armatureClip.x - 25 + armatureClip.x), (-armatureClip.y  + armatureClip.y - 65), (armatureClip.width), (armatureClip.height), false)));
			armatureBody.allowMovement = true;
			armatureBody.allowRotation = false;
			armatureBody.mass = 100;
			armatureBody.graphic = armature.display as Sprite;
			armatureBody.space = space;
			armatureBody.graphicUpdate = updateGraphics;
			
			return armatureBody;
		}
		
//---------------------------------------------------------------------------------------------------------------------------------balls
		private function addBalls():void {
			for (var i:int = 0; i < NUMBER_OF_BALLS; i++) {
				addBall();
			}
		}
		
		private function addBall():void {
			addChild(createNewBall().graphic);
		}
		
		private function createNewBall():Body {
			const ball:Body = new Body(BodyType.DYNAMIC, new Vec2(ballRandomX, BALL_Y));
			
			ball.shapes.add(new Circle(BALL_RADIUS, null, new Material(BALL_ELASTICITY)));
			ball..mass = 10;
			ball.space = space;
			ball.graphic = new plCircle();
			ball.graphicUpdate = updateGraphics;
			
			return ball;
		}
		
		private function get ballRandomX():Number {
			return Math.random() * stage.stageWidth + (Math.random() + 10 * 5);
		}
		
//---------------------------------------------------------------------------------------------------------------------------------boxes
		private function addBoxs():void {
			for (var i:int = 0; i < NUMBER_OF_BOXS; i++) {
				addBox();
			}
		}
		
		private function addBox():void {
			addChild(createNewBox().graphic);
		}
		
		private function createNewBox():Body {
			const box:Body = new Body(BodyType.DYNAMIC, new Vec2(boxRandomX, BOX_Y));
			
			// Start the Nape Rect at (-32,-32) and double the box_Radius since the pivot point is in the middle and its only half of size of the image (64,64)
			box.shapes.add(new Polygon(Polygon.rect(-32, -32, BOX_RADIUS * 2, BOX_RADIUS * 2)));
			box..mass = 1;
			
			box.space = space;
			box.graphic = new plBox();
			box.graphicUpdate = updateGraphics;
			
			return box;
		}
		
		private function get boxRandomX():Number {
			return Math.random() * 750 + (Math.random() + 10 * 5);
		}
		
//---------------------------------------------------------------------------------------------------------------------------------gfx		
		private function updateGraphics(body:Body):void {
			body.graphic.x = body.position.x;
			body.graphic.y = body.position.y;
			body.graphic.rotation = body.rotation
		}
	}
}