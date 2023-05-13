type as ulong color_t

'' Scales the velocity of the player-asteroid impact.
'' Controls how much damage the player ship takes when
'' colliding with asteroids. 
const as single C_DAMAGE_SCALE = 0.007f

enum Colors
  WHITE  = rgba( 255, 255, 255, 255 )
  RED    = rgba( 255, 0, 0, 255 )
  YELLOW = rgba( 255, 255, 0, 255 )
  BLUE   = rgba( 0, 0, 255, 255 )
end enum

'' Returns a normalized vector in a random direction
function rndNormal() as Vec2
  return( Vec2( rng( -1.0f, 1.0f ), rng( -1.0f, 1.0f ) ).normalized() )
end function

'' Returns a position within an area
function rngWithin( bb as BoundingBox ) as Vec2
  return( Vec2( rng( bb.x, bb.width ), rng( bb.y, bb.height ) ) )
end function

sub renderTriangle( _
  x1 as long, y1 as long,_
  x2 as long, y2 as long, _
  x3 as long, y3 as long, _
  c as ulong, buffer as any ptr = 0 )
  
  if( y2 < y1 ) then swap y1, y2 : swap x1, x2 : end if
  if( y3 < y1 ) then swap y3, y1 : swap x3, x1 : end if
  if( y3 < y2 ) then swap y3, y2 : swap x3, x2 : end if
  
  dim as long _
    delta1 = iif( y2 - y1 <> 0, ( ( x2 - x1 ) shl 16 ) \ ( y2 - y1 ), 0 ), _
    delta2 = iif( y3 - y2 <> 0, ( ( x3 - x2 ) shl 16 ) \ ( y3 - y2 ), 0 ), _
    delta3 = iif( y1 - y3 <> 0, ( ( x1 - x3 ) shl 16 ) \ ( y1 - y3 ), 0 )
  
  '' Top half
  dim as long lx = x1 shl 16, rx = lx
  
  for y as integer = y1 to y2 - 1
    line buffer, ( lx shr 16, y ) - ( rx shr 16, y ), c 
    lx = lx + delta1 : rx = rx + delta3
  next
  
  '' Bottom half
  lx = x2 shl 16
  
  for y as integer = y2 to y3
    line buffer, ( lx shr 16, y ) - ( rx shr 16, y ), c 
    lx = lx + delta2 : rx = rx + delta3
  next
end sub

type Game extends Object
  declare static sub init( as long, as long )
  
  static as BoundingBox playArea
  static as KeyboardInput keyboard
end type

static as KeyboardInput Game.keyboard
static as BoundingBox Game.playArea = BoundingBox()

sub Game.init( xRes as long, yRes as long )
  screenRes( xRes, yRes, 32, 2 )
  screenSet( 0, 1 )
  
  randomize()
  
  playArea = BoundingBox( -20, -20, xRes + 20, yRes + 20 )
end sub
