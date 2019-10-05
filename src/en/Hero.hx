package en;

class Hero extends Entity {
	var ca : dn.heaps.Controller.ControllerAccess;
	public var item : Null<Item>;

	public function new(x,y) {
		super(x,y);
		ca = Main.ME.controller.createAccess("hero");

		spr.anim.registerStateAnim("heroThrow", 2, 0.05, function() return isLocked() && cd.has("throwingItem") );
		spr.anim.registerStateAnim("heroGrab", 2, function() return isLocked() && cd.has("grabbingItem") );
		spr.anim.registerStateAnim("heroRun", 1, 0.2, function() return M.fabs(dxTotal)>=0.04 || M.fabs(dyTotal)>=0.04);
		spr.anim.registerStateAnim("heroIdle", 0, 0.4);
	}

	override function dispose() {
		super.dispose();
		dropItem();
		ca.dispose();
	}

	function dropItem() {
		if( item!=null ) {
			item.setPosCase(cx,cy,xr,yr);
			item.dx = -dir*0.1;
			item.spr.rotation = 0;
			item = null;
		}
	}

	function throwItem() {
		if( item!=null ) {
			var e = item;
			game.delayer.addS( function() {
				if( isAlive() && e.isAlive() ) {
					dropItem();
					var leftDist = M.dist(0,0, ca.lxValue(), ca.lyValue());
					var a = leftDist<=0.3 ? dir==1?0:M.PI : Math.atan2(-ca.lyValue(), ca.lxValue());
					var s = 0.4;
					e.bump(Math.cos(a)*s, Math.sin(a)*s, 0.2);
				}
			}, 0.25);
			lockS(0.3);
			cd.setS("throwingItem", getLockS()-0.1);
		}
	}

	function pickItem(e:Item) {
		dropItem();
		dx*=0.3;
		dy*=0.3;
		dir = dirTo(e);
		item = e;
		lockS(0.3);
		cd.setS("grabbingItem", getLockS()-0.1);
	}

	override function postUpdate() {
		super.postUpdate();
		if( item!=null ) {
			if( cd.has("grabbingItem") )
				item.setPosPixel(footX+dir*10, footY+1);
			else if( cd.has("throwingItem") ) {
				item.spr.rotation = 0;
				item.setPosPixel(footX-dir*4, footY-8);
			}
			else {
				item.spr.rotation = dir*0.2;
				if( M.fabs(dxTotal)>=0.03 || M.fabs(dyTotal)>=0.03 )
					item.setPosPixel(footX-dir*4, footY-3);
				else
					item.setPosPixel(footX-dir*3, footY-2);
			}
		}
	}

	override function update() {
		super.update();

		if( !isLocked() ) {
			// Move
			var leftDist = M.dist(0,0, ca.lxValue(), ca.lyValue());
			if( leftDist>=0.3 ) {
				var a = Math.atan2(-ca.lyValue(), ca.lxValue());
				var s = 0.01 * leftDist * tmod;
				dx+=Math.cos(a)*s;
				dy+=Math.sin(a)*s;
				if( ca.lxValue()<0.3 ) dir = -1;
				if( ca.lxValue()>0.3 ) dir = 1;
			}
			else {
				dx *= Math.pow(0.6,tmod);
				dy *= Math.pow(0.6,tmod);
			}

			// Items
			if( ca.xPressed() && item==null ) {
				var dh = new dn.DecisionHelper(Item.ALL);
				dh.keepOnly( function(e) return e.isAlive() && !e.isGrabbed() && ( sightCheckEnt(e) && distCase(e)<=1.5 || distCase(e)<=0.8 ) );
				dh.score( function(e) return -distCase(e) );
				var e = dh.getBest();
				if( e!=null )
					pickItem(e);
			}
			else if( ca.xPressed() && item!=null )
				throwItem();
		}

		// Lost item
		if( item!=null && !item.isAlive() )
			item = null;

		// if( ca.xPressed() )
			// dn.Bresenham.iterateDisc(cx,cy, 4, function(cx,cy) {
			// 	level.damage(cx,cy, 0.35);
			// });

		// Roof anim
		if( level.hasRoof(cx,cy) )
			level.eraseRoofFrom(cx,cy);
		else
			level.clearRoofErase();
	}
}