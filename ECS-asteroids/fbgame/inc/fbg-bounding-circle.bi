#ifndef __FBGAME_BOUNDINGCIRCLE__
#define __FBGAME_BOUNDINGCIRCLE__

#include once "fbg-vec2.bi"
#include once "fbg-bounding-box.bi"

namespace __FBG_NS__
  type BoundingCircle
    declare constructor()
    declare constructor( as single, as single, as single )
    declare constructor( as Vec2, as single )
    declare destructor()
    
    declare function centerAt( as single, as single ) byref as BoundingCircle
    declare function inside( as single, as single ) as boolean
    declare function outside( as single, as single ) as boolean
    declare function overlapsWith( as BoundingCircle ) as boolean
    declare function overlapsWith( as BoundingBox ) as boolean
    declare function overlapVector( as BoundingCircle ) as Vec2
    
    as Vec2 center
    as single radius
  end type
  
  constructor BoundingCircle() : end constructor
  
  constructor BoundingCircle( aX as single, aY as single, aRadius as single )
    constructor( Vec2( aX, aY ), aRadius )
  end constructor
  
  constructor BoundingCircle( aCenter as Vec2, aRadius as single )
    center = aCenter
    radius = aRadius
  end constructor
  
  destructor BoundingCircle() : end destructor
  
  private function BoundingCircle.centerAt( aX as single, aY as single ) byref as BoundingCircle
    center.x = aX : center.y = aY
    
    return( this )
  end function
  
  private function BoundingCircle.inside( aX as single, aY as single ) as boolean
    return( Vec2( aX, aY ).distanceToSq( center ) <= radius ^ 2 )
  end function
  
  private function BoundingCircle.outside( aX as single, aY as single ) as boolean
    return( not inside( aX, aY ) )
  end function
  
  private function BoundingCircle.overlapsWith( another as BoundingCircle ) as boolean
    return( cbool( ( center - another.center ).lengthSq() < ( radius + another.radius ) ^ 2 ) )
  end function
  
  private function BoundingCircle.overlapsWith( bb as BoundingBox ) as boolean
    return( cbool( Vec2( _
      iif( center.x < bb.x, bb.x, iif( center.x > bb.x + bb.width, _
        bb.x + bb.width, center.x ) ), _
      iif( center.y < bb.y, bb.y, iif( center.y > bb.y + bb.height, _
        bb.y + bb.height, center.y ) ) ).distanceTo( center ) <= radius ) )
  end function
  
  private function BoundingCircle.overlapVector( another as BoundingCircle ) as Vec2
    return( iif( overlapsWith( another ), ( center - another.center ), Vec2.zero() ) )
  end function
  
  private function BoundingBox.overlapsWith( bc as BoundingCircle ) as boolean
    return( cbool( Vec2( _
      iif( bc.center.x < x, x, iif( bc.center.x > x + width, _
        x + width, bc.center.x ) ), _
      iif( bc.center.y < y, y, iif( bc.center.y > y + height, _
        y + height, bc.center.y ) ) ).distanceTo( bc.center ) <= bc.radius ) )
  end function
end namespace

#endif
