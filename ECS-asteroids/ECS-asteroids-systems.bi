#ifndef __ECS_ASTEROIDS_SYSTEMS__
#define __ECS_ASTEROIDS_SYSTEMS__

enum GAME_EVENTS
  EV_GAME_ENTITYDESTROYED = 1000
end enum

type GameEntityDestroyedEventArgs extends ECSEventArgs
  declare constructor( as ECSEntity, as ECSEntity, as ECSEntities, as ECSComponents )
  
  as ECSEntity destroyed, author
  as ECSEntities ptr e
  as ECSComponents ptr c
end type

constructor GameEntityDestroyedEventArgs( d as ECSEntity, a as ECSEntity, ent as ECSEntities, com as ECSComponents )
  destroyed = d : author = a : e = @ent : c = @com
end constructor

sub move( m as Position, p as Physics, dt as double )
  if( p.vel.lengthSq() > p.maxSpeed ^ 2 ) then
    p.vel = p.vel.normalized() * p.maxSpeed
  end if
  
  m.pos += p.vel * dt
end sub

type MovableSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Physics ptr ph
end type

constructor MovableSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  p = requires( "position" )
  ph = requires( "physics" )
end constructor

destructor MovableSystem() : end destructor

sub MovableSystem.process( dt as double = 0.0d )
  for each e as ECSEntity in processed
    move( p[ e ], ph[ e ], dt )
    
    '' Wrap around play area
    p[ e ].pos = wrapV( p[ e ].pos, _
      Game.playArea.x, Game.playArea.y, _
      Game.playArea.width, Game.playArea.height )
  next
end sub

sub accelerate( p as Physics, a as Vec2 )
  p.vel += a 
end sub

sub rotate( o as Orientation, a as single )
  o.dir = o.dir.rotated( rad( a ) ).normalize()
end sub

sub shoot( e as ECSEntities, c as ECSComponents, _
  m as Position, o as Orientation, ph as Physics, owner as ECSEntity, dt as double )
  
  '' Choose a random direction arc
  var vel = o.dir.rotated( rad( rng( -3.0f, 3.0f ) ) ).normalize()
  
  '' Spawn bullet
  newBullet( e, c, m.pos, vel, 500.0f, 2000.0f, owner )
  
  '' Add a little backwards acceleration to the shooting entity
  '' when firing.
  accelerate( ph, -o.dir.normalized() * 400.0f * dt )
end sub

type ControllableSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Controls ptr ctrl
    as ControlParameters ptr params
    as Position ptr p
    as Orientation ptr o
    as Physics ptr ph
end type

constructor ControllableSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  ctrl = requires( "controls" )
  params = requires( "controlparameters" )
  p = requires( "position" )
  o = requires( "orientation" )
  ph = requires( "physics" )
end constructor

destructor ControllableSystem() : end destructor

sub ControllableSystem.process( dt as double = 0.0d )
  for each e as ECSEntity in processed
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
        shoot( myEntities, myComponents, p[ e ], o[ e ], ph[ e ], e, dt )
      end if
      
      if( Game.keyboard.repeated( .fire, params[ e ].rateOfFire ) ) then
        shoot( myEntities, myComponents, p[ e ], o[ e ], ph[ e ], e, dt )
      end if
    end with
  next
end sub

type LifetimeSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  declare sub process( as double = 0.0d )
  
  private:
    as Lifetime ptr lt
end type

constructor LifetimeSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  lt = requires( "lifetime" )
end constructor

destructor LifetimeSystem() : end destructor

sub LifetimeSystem.process( dt as double = 0.0d )
  var deleted = UnorderedList( processed.count )
  
  for each e as ECSEntity in processed
    lt[ e ].value -= 1000.0f * dt
    
    if( lt[ e ].value < 0 ) then
      deleted.add( e )
    end if
  next
  
  for i as integer = 0 to deleted.count - 1
    myEntities.destroy( deleted[ i ] )
  next
end sub

'' Physics and collision detection and response
function getCollisionNormal( N as Vec2, v1 as Vec2, v2 as Vec2 ) as Vec2
  '' Compute tangent vector to normal and relative velocities
  '' of the collision.
  var _
    tangent = N.turnedRight().normalize(), _
    vRel = v1 - v2
  
  '' Compute length of the relative velocity projected on the
  '' tangent axis.
  dim as single l = vRel.dot( tangent )
  
  '' Decompose into normal and tangential velocities, and return
  '' the normal velocity.
  return( vRel - ( tangent * l ) )
end function

function resolveCollision( _
    bc1 as BoundingCircle, bc2 as BoundingCircle, vN as Vec2, vel1 as Vec2, vel2 as Vec2 ) _
  as Vec2
  
  '' Compute the Minimum Translation Vector to move the
  '' overlapping circles out of collision.
  var mtv = _
    -( ( bc1.center - bc2.center ) - ( bc1.center - bc2.center ).ofLength( _
         bc1.radius + bc2.radius ) )
    
  '' And reflect the velocities along the normal of
  '' the collision.
  vel1 -= vN
  vel2 += vN
  
  return( mtv )
end function

function collided( _
    a1 as BoundingCircle, a2 as BoundingCircle, vel1 as Vec2, vel2 as Vec2 ) _
  as Vec2
  
  '' Compute collision normal
  var vN = getCollisionNormal( ( a1.center - a2.center ), vel1, vel2 )
   
  '' Resolve the collision
  return( resolveCollision( a1, a2, vN, vel1, vel2 ) )
end function

type CollidableSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Physics ptr ph
    as Dimensions ptr d
    as Collision ptr coll
end type

constructor CollidableSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  p = requires( "position" )
  ph = requires( "physics" )
  d = requires( "dimensions" )
  coll = requires( "collision" )
end constructor

destructor CollidableSystem() : end destructor

sub CollidableSystem.process( dt as double = 0.0d )
  var a1 = BoundingCircle()
  var a2 = BoundingCircle()
  
  for i as integer = 0 to processed.count - 1
    dim as ECSEntity e1 = processed[ i ]
    
    a1.center = p[ e1 ].pos
    a1.radius = coll[ e1 ].radius
    
    for j as integer = i + 1 to processed.count - 1
      dim as ECSEntity e2 = processed[ j ]
      
      a2.center = p[ e2 ].pos
      a2.radius = coll[ e2 ].radius
      
      if( a1.overlapsWith( a2 ) ) then
        var mtv = collided( a1, a2, ph[ e1 ].vel, ph[ e2 ].vel )
        
        '' Adjust the position of the entities
        p[ e1 ].pos += mtv * 0.5f
        p[ e2 ].pos -= mtv * 0.5f
      end if
    next
  next
end sub

type ShootableSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Collision ptr coll
    as Dimensions ptr d
    as Lifetime ptr lt
    as Health ptr h
    as Parent ptr prnt
end type

constructor ShootableSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  has( "type:asteroid" )
  has( "type:bullet" )
  
  lt = has( "lifetime" )
  h = has( "health" )
  p = requires( "position" )
  d = requires( "dimensions" )
  
  prnt = myComponents[ "parent" ]
end constructor

destructor ShootableSystem() : end destructor

#macro filter?( _v_, _p_, _f_, _r_ )
var _r_ = UnorderedList( _p_.count )

for each _v_ in _p_
  if( _f_ ) then
    _r_.add( e )
  end if
next
#endmacro

#define like ,

sub ShootableSystem.process( dt as double = 0.0d )
  filter e as ECSEntity in processed like contains( e, "type:bullet" ) in bullets
  filter e as ECSEntity in processed like not contains( e, "type:bullet" ) in asteroids
  
  var abb = BoundingCircle(), bbb = BoundingCircle()
  
  for each b as ECSEntity in bullets
    bbb.center = p[ b ].pos
    bbb.radius = d[ b ].size
    
    for each a as ECSEntity in asteroids
      abb.center = p[ a ].pos
      abb.radius = d[ a ].size
      
      if( bbb.overlapsWith( abb ) ) then
        '' Collided
        circle( abb.center.x, abb.center.y ), d[ a ].size, WHITE, , , , f
        
        lt[ b ].value = 0.0f
        h[ a ].value -= 30.0f
        
        '' Did we destroy the asteroid?
        if( h[ a ].value < 0.0f ) then
          ECS.raiseEvent( EV_GAME_ENTITYDESTROYED, _
            GameEntityDestroyedEventArgs( a, prnt[ b ].id, myEntities, myComponents ), @this )
        end if
      end if 
    next
  next
end sub

type HealthSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  declare sub process( as double = 0.0d )
  
  private:
    as Health ptr h
end type

constructor HealthSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  h = requires( "health" )
end constructor

destructor HealthSystem() : end destructor

sub HealthSystem.process( dt as double = 0.0d )
  var destroyed = UnorderedList( processed.count )
  
  for each e as ECSEntity in processed
    if( h[ e ].value < 0.0f ) then
      destroyed.add( e )
    end if
  next
  
  for each e as ECSEntity in destroyed
    myEntities.destroy( e )
  next
end sub

type AsteroidDestroyedSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  private:
    declare static sub event_gameEntityDestroyed( _
      as any ptr, as GameEntityDestroyedEventArgs, as AsteroidDestroyedSystem ptr )
    
    as Position ptr p
    as Dimensions ptr d
end type

constructor AsteroidDestroyedSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  ECS.registerListener( EV_GAME_ENTITYDESTROYED, toHandler( event_gameEntityDestroyed ), @this )
  
  p = cast( Position ptr, myComponents[ "position" ] )
  d = cast( Dimensions ptr,myComponents[ "dimensions" ] )
end constructor

destructor AsteroidDestroyedSystem()
  ECS.unregisterListener( EV_GAME_ENTITYDESTROYED, toHandler( event_gameEntityDestroyed ), @this )
end destructor

sub AsteroidDestroyedSystem.event_gameEntityDestroyed( _
  sender as any ptr, e as GameEntityDestroyedEventArgs, receiver as AsteroidDestroyedSystem ptr )
  
  if( e.c->hasComponent( e.destroyed, "type:asteroid" ) ) then
    var p = receiver->p[ e.destroyed ].pos
    var s = receiver->d[ e.destroyed ].size
    
    dim as single size = s * 0.25
    
    if( size >= 4.0f ) then
      for i as integer = 1 to 3
        newAsteroid( *e.e, *e.c, p, rndNormal() * ( 400.0f - size * 10.0f ), size )
      next
    end if
    
    Debug.print( "I was killed by: " & e.e->getName( e.author ) )
    Debug.print( "Its parent is: " & e.e->getName( cast( Parent ptr, ( *e.c )[ "parent" ] )[ e.author ].id ) )
  end if
end sub

type ScoreSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  private:
    declare static sub event_gameEntityDestroyed( _
      as any ptr, as GameEntityDestroyedEventArgs, as ScoreSystem ptr )
    
    as Score ptr sc
end type

constructor ScoreSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  ECS.registerListener( EV_GAME_ENTITYDESTROYED, toHandler( event_gameEntityDestroyed ), @this )
end constructor

destructor ScoreSystem()
  ECS.unregisterListener( EV_GAME_ENTITYDESTROYED, toHandler( event_gameEntityDestroyed ), @this )
end destructor

sub ScoreSystem.event_gameEntityDestroyed( _
  sender as any ptr, e as GameEntityDestroyedEventArgs, receiver as ScoreSystem ptr )
  
  if( e.e->getName( e.author ) = "playership" ) then
    component( *e.c, component( *e.c, e.author, Parent ).id, Score ) _
      .value += component( *e.c, e.destroyed, ScoreValue ).value
  end if
end sub

type ShipRenderSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Orientation ptr o
    as Dimensions ptr d
    as Appearance ptr a
end type

constructor ShipRenderSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  requires( "type:ship" )
  p = requires( "position" ) 
  o = requires( "orientation" )
  d = requires( "dimensions" )
  a = requires( "appearance" )
end constructor

destructor ShipRenderSystem() : end destructor

sub ShipRenderSystem.process( dt as double = 0.0d )
  for each e as ECSEntity in processed
    with p[ e ]
      var _
        p0 = .pos + o[ e ].dir * d[ e ].size, _
        p1 = .pos + o[ e ].dir.turnedLeft() * ( d[ e ].size * 0.5f ), _
        p2 = .pos + o[ e ].dir.turnedRight() * ( d[ e ].size * 0.5f )
      
      renderTriangle( p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, a[ e ].color )
      circle( .pos.x, .pos.y ), 5.0f, a[ e ].color, , , , f
    end with
  next
end sub

type AsteroidRenderSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Dimensions ptr d
    as Appearance ptr a
end type

constructor AsteroidRenderSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  requires( "type:asteroid" )
  p = requires( "position" )
  d = requires( "dimensions" )
  a = requires( "appearance" )
end constructor

destructor AsteroidRenderSystem() : end destructor

sub AsteroidRenderSystem.process( dt as double = 0.0d )
  for each e as ECSEntity in processed
    with p[ e ]
      circle( .pos.x, .pos.y ), d[ e ].size, a[ e ].color, , , , f
    end with
  next
end sub

type BulletRenderSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Physics ptr ph
end type

constructor BulletRenderSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  requires( "type:bullet" )
  p = requires( "position" )
  ph = requires( "physics" )
end constructor

destructor BulletRenderSystem() : end destructor

sub BulletRenderSystem.process( dt as double = 0.0d )
  for each e as ECSEntity in processed
    with p[ e ]
      circle( .pos.x, .pos.y ), 4, BLUE
      circle( .pos.x, .pos.y ), 3, rgb( 168, 228, 251 )
      circle( .pos.x, .pos.y ), 2, WHITE, , , , f
    end with
  next
end sub

#endif
