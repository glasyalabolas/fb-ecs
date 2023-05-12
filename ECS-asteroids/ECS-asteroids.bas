#include once "fbgame/fb-game.bi"
#include once "../fb-ecs.bi"

Debug.toConsole()

'' Experimental syntax
#macro withComponent( _c_, _p_ )
  with *cast( _c_ ptr, _p_ )
#endmacro

#define asComponent( _c_, _p_ ) *cast( _c_ ptr, _p_ )

#define in ,

#macro each?( _e_, _p_ )
  i as integer = 0 to _p_.count - 1
  dim _e_ = _p_[ i ]
#endmacro

using FbGame

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

'' Components
type Movable
  as Vec2 pos
end type

type Orientable
  as Vec2 dir
end type

type Physics
  as Vec2 vel
  as single maxSpeed
end type

type Appearance
  as color_t color
end type

type Dimensions
  as single size
end type

type Controllable
  as long _
    forward, backward, _
    rotateLeft, rotateRight, _
    fire, strafe
end type

type Health
  as single value
end type

type Score
  as ulong value
end type

type Speed
  as single value
end type

type Lifetime
  as single value
end type

type Collidable
  as BoundingCircle shape
end type

type Ship
  as Entity shipID
end type

type ControlParameters
  as single rateOfFire, accel, turnSpeed
end type

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
  
  static as const long MAX_ASTEROIDS
  static as BoundingBox playArea
  static as KeyboardInput keyboard
end type

static as const long Game.MAX_ASTEROIDS = 1000
static as KeyboardInput Game.keyboard
static as BoundingBox Game.playArea = BoundingBox()

sub Game.init( xRes as long, yRes as long )
  screenRes( xRes, yRes, 32, 2 )
  screenSet( 0, 1 )
  
  randomize()
  
  playArea = BoundingBox( -20, -20, xRes + 20, yRes + 20 )
end sub

function createShip( e as Entities, c as Components ) as Entity
  var pship = e.create( "playership" )
  
  asComponent( Movable, c.addComponent( pship, "movable" ) ) _
    .pos = Vec2( Game.playArea.width / 2, Game.playArea.height / 2 )
  asComponent( Orientable, c.addComponent( pship, "orientable" ) ) _
    .dir = Vec2( 0.0, -1.0 )
  
  withComponent( Physics, c.addComponent( pship, "physics" ) )
    .vel = Vec2( 0.0, 0.0 )
    .maxSpeed = 300.0f
  end with
  
  asComponent( Dimensions, c.addComponent( pship, "dimensions" ) ) _
    .size = 20.0f
  asComponent( Appearance, c.addComponent( pship, "appearance" ) ) _
    .color = YELLOW
  
  withComponent( ControlParameters, c.addComponent( pship, "controlparameters" ) )
    .accel = 550.0f
    .turnSpeed = 360.0f
    .rateOfFire = 100.0f
  end with
  
  withComponent( Controllable, c.addComponent( pship, "controllable" ) )
    .forward = Fb.SC_UP
    .backward = Fb.SC_DOWN
    .rotateLeft = Fb.SC_LEFT
    .rotateRight = Fb.SC_RIGHT
    .fire = Fb.SC_SPACE
    .strafe = Fb.SC_LSHIFT
  end with
  
  c.addComponent( pship, "type:ship" )
  
  return( pship )
end function

function createPlayer( e as Entities, c as Components ) as Entity
  var player = e.create( "player" )
  
  asComponent( Health, c.addComponent( player, "health" ) ) _
    .value = 1000.0f
  asComponent( Score, c.addComponent( player, "score" ) ) _
    .value = 0
  asComponent( Ship, c.addComponent( player, "ship" ) ) _
    .shipID = createShip( e, c )
  
  return( player )
end function

sub createAsteroids( e as Entities, c as Components, count as long )
  for i as integer = 1 to count
    var asteroid = e.create()
    
    dim as single size = rng( 8.0f, 40.0f )
    
    asComponent( Movable, c.addComponent( asteroid, "movable" ) ) _
      .pos = rngWithin( Game.playArea )
    withComponent( Physics, c.addComponent( asteroid, "physics" ) )
      .vel = Vec2( rng( -1.0f, 1.0f ), rng( -1.0f, 1.0f ) ) * ( 200.0f - size * 5.0f )
      .maxSpeed = 100.0f
    end with
    
    asComponent( Dimensions, c.addComponent( asteroid, "dimensions" ) ) _
      .size = size
    asComponent( Appearance, c.addComponent( asteroid, "appearance" ) ) _
      .color = RED
    asComponent( Health, c.addComponent( asteroid, "health" ) ) _
      .value = 100.0f
    
    c.addComponent( asteroid, "type:asteroid" )
  next
end sub

type ShipRenderSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Movable ptr m
    as Orientable ptr o
    as Dimensions ptr d
    as Appearance ptr a
end type

constructor ShipRenderSystem( e as Entities, c as Components )
  base( e, c )
  
  requires( "type:ship" )
  m = requires( "movable" ) 
  o = requires( "orientable" )
  d = requires( "dimensions" )
  a = requires( "appearance" )
end constructor

destructor ShipRenderSystem() : end destructor

sub ShipRenderSystem.process( dt as double = 0.0d )
  for each e as Entity in processed
    with m[ e ]
      var _
        p0 = .pos + o[ e ].dir * d[ e ].size, _
        p1 = .pos + o[ e ].dir.turnedLeft() * ( d[ e ].size * 0.5f ), _
        p2 = .pos + o[ e ].dir.turnedRight() * ( d[ e ].size * 0.5f )
      
      renderTriangle( p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, a[ e ].color )
      circle( .pos.x, .pos.y ), 5, a[ e ].color, , , , f
    end with
  next
end sub

type AsteroidRenderSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Movable ptr m
    as Dimensions ptr d
    as Appearance ptr a
end type

constructor AsteroidRenderSystem( e as Entities, c as Components )
  base( e, c )
  
  requires( "type:asteroid" )
  m = requires( "movable" )
  d = requires( "dimensions" )
  a = requires( "appearance" )
end constructor

destructor AsteroidRenderSystem() : end destructor

sub AsteroidRenderSystem.process( dt as double = 0.0d )
  for each e as Entity in processed
    with m[ e ]
      circle( .pos.x, .pos.y ), d[ e ].size, a[ e ].color, , , , f
    end with
  next
end sub

sub move( m as Movable, p as Physics, dt as double )
  if( p.vel.lengthSq() > p.maxSpeed ^ 2 ) then
    p.vel = p.vel.normalized() * p.maxSpeed
  end if
  
  m.pos += p.vel * dt
end sub

type MovableSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Movable ptr m
    as Physics ptr ph
end type

constructor MovableSystem( e as Entities, c as Components )
  base( e, c )
  
  m = requires( "movable" )
  ph = requires( "physics" )
end constructor

destructor MovableSystem() : end destructor

sub MovableSystem.process( dt as double = 0.0d )
  for each e as Entity in processed
    move( m[ e ], ph[ e ], dt )
    
    m[ e ].pos = wrapV( m[ e ].pos, _
      Game.playArea.x, Game.playArea.y, _
      Game.playArea.width, Game.playArea.height )
  next
end sub

sub accelerate( p as Physics, a as Vec2 )
  p.vel += a 
end sub

sub rotate( o as Orientable, a as single )
  o.dir = o.dir.rotated( rad( a ) ).normalize()
end sub

type ControllableSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Controllable ptr ctrl
    as ControlParameters ptr params
    as Movable ptr m
    as Orientable ptr o
    as Physics ptr ph
end type

constructor ControllableSystem( e as Entities, c as Components )
  base( e, c )
  
  ctrl = requires( "controllable" )
  params = requires( "controlparameters" )
  m = requires( "movable" )
  o = requires( "orientable" )
  ph = requires( "physics" )
end constructor

destructor ControllableSystem() : end destructor

sub ControllableSystem.process( dt as double = 0.0d )
  for each e as Entity in processed
    with ctrl[ e ]
      dim as boolean strafing
      
      if( Game.keyboard.held( .forward ) ) then
        accelerate( ph[ e ], o[ e ].dir * params[ e ].accel * dt )
      end if
      
      if( Game.keyboard.held( .backward ) ) then
        accelerate( ph[ e ], o[ e ].dir * -params[ e ].accel * dt )
      end if
      
      if( Game.keyboard.held( .strafe ) ) then
        strafing = true
      end if
      
      if( Game.keyboard.held( .rotateLeft ) ) then
        if( strafing ) then
          accelerate( ph[ e ], o[ e ].dir.turnedRight() * params[ e ].accel * dt )
        else
          rotate( o[ e ], -params[ e ].turnSpeed * dt )
        end if
      end if
      
      if( Game.keyboard.held( .rotateRight ) ) then
        if( strafing ) then
          accelerate( ph[ e ], o[ e ].dir.turnedLeft() * params[ e ].accel * dt )
        else
          rotate( o[ e ], params[ e ].turnSpeed * dt )
        end if
      end if
      
      if( Game.keyboard.pressed( .fire ) ) then
        'shoot( state, sh, dt )
      end if
      
      if( Game.keyboard.repeated( .fire, params[ e ].rateOfFire ) ) then
        'shoot( state, sh, dt )
      end if
    end with
  next
end sub

var AEntities = Entities(), AComponents = Components()

registerComponent( AComponents, "movable", Movable )
registerComponent( AComponents, "orientable", Orientable )
registerComponent( AComponents, "physics", Physics )
registerComponent( AComponents, "appearance", Appearance )
registerComponent( AComponents, "dimensions", Dimensions )
registerComponent( AComponents, "controllable", Controllable )
registerComponent( AComponents, "health", Health )
registerComponent( AComponents, "score", Score )
registerComponent( AComponents, "speed", Speed )
registerComponent( AComponents, "lifetime", Lifetime )
registerComponent( AComponents, "collidable", Collidable )
registerComponent( AComponents, "ship", Ship )
registerComponent( AComponents, "controlparameters", ControlParameters )

AComponents.register( "type:ship" )
AComponents.register( "type:asteroid" )
AComponents.register( "type:bullet" )

/'
  Main code
'/
Game.init( 800, 600 )

var r = ShipRenderSystem( AEntities, AComponents )
var ar = AsteroidRenderSystem( AEntities, AComponents )
var m = MovableSystem( AEntities, AComponents )
var ctrl = ControllableSystem( AEntities, AComponents )

createShip( AEntities, AComponents )
createAsteroids( AEntities, AComponents, 30 )

dim as double dt
dim as Fb.Event ev

do
  do while( screenEvent( @ev ) )
    Game.keyboard.onEvent( @ev )
  loop
  
  if( Game.keyboard.pressed( Fb.SC_R ) ) then
    var p = AEntities.find( "playership" )
    AComponents.removeComponent( p, "controllable" )
  end if
  
  if( Game.keyboard.pressed( Fb.SC_A ) ) then
    var p = AEntities.find( "playership" )
    AComponents.addComponent( p, "controllable" )
  end if
  
  '' Update
  ctrl.process( dt )
  m.process( dt )
  
  '' Render
  dt = timer()
    cls()
      r.process()
      ar.process()
      ? "Controllable is processing: " & ctrl.processed.count & " entities."
      ? "Movable is processing: " & m.processed.count & " entities."
      ? "Rendering is processing: " & r.processed.count & " entities."
      ? "Asteroid rendering is processing: " & ar.processed.count & " entities."
    flip()
    
    sleep( 1, 1 )
  dt = timer() - dt
loop until( Game.keyboard.pressed( Fb.SC_ESCAPE ) )
