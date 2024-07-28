#ifndef __ECS_ASTEROIDS_SYSTEMS__
#define __ECS_ASTEROIDS_SYSTEMS__

'' Some event IDs for the game needs
enum GAME_EVENTS
  EV_GAME_ENTITY_COLLIDED = 1000 
  EV_GAME_ENTITY_DESTROYED
  EV_GAME_ENTITY_SHOT
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

/'
  Here is where the logic of the game should happen: systems.
  
  Below are various samples of how you can implement different systems that can do a variety
  of things, using helper functions, etc.
  
  Systems derive from a base class that can raise and listen to events (so they can communicate
  with other systems or the main program). All events are SYNCHRONOUS, meaning that they will
  execute as soon as they are raised.
  
  The systems themselves declare what entities they are interested in processing in their 
  constructors, using various methods described on the comments below, so all you really have 
  to do is add/remove components to entities, and systems will update themselves automatically
  and start processing the appropriate entities.
'/
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
  '' The base constructor should always be called, to pass them a reference to the
  '' entity and component instances relevant to this system.
  base( e, c )
  
  '' 'Require' means that the system needs the component present to start processing
  '' the entity. You then get a pointer to the relevant component array.
  require Position in p
  require Physics in ph
end constructor

destructor MovableSystem() : end destructor

sub MovableSystem.process( dt as double = 0.0d )
  for each e as ECSEntity in processed
    move( p[ e ], ph[ e ], dt )
    
    '' Wrap around play area
    p[ e ].pos = wrapV( p[ e ].pos, Game.playArea.x, Game.playArea.y, Game.playArea.width, Game.playArea.height )
  next
end sub

sub accelerate( p as Physics, a as Vec2 )
  p.vel += a 
end sub

sub rotate( o as Orientation, a as single )
  o.dir = o.dir.rotated( rad( a ) ).normalize()
end sub

sub shoot( e as ECSEntities, c as ECSComponents, _
  m as Position, o as Orientation, ph as Physics, parent as ECSEntity, dt as double )
  
  '' Choose a random direction arc
  var vel = o.dir.rotated( rad( rng( -3.0f, 3.0f ) ) ).normalize()
  
  '' Spawn bullet
  newBullet( e, c, m.pos, vel, 500.0f, 2000.0f, parent )
  
  '' Add a little backwards acceleration to the shooting entity
  '' when firing.
  accelerate( ph, -o.dir.normalized() * 300.0f * dt )
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
  
  require Controls in ctrl
  require ControlParameters in params
  require Position in p
  require Orientation in o
  require Physics in ph
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
  
  require Lifetime in lt
end constructor

destructor LifetimeSystem() : end destructor

sub LifetimeSystem.process( dt as double = 0.0d )
  var deleted = UnorderedList( processed.count )
  
  for each e as ECSEntity in processed
    lt[ e ].current -= 1000.0f * dt
    
    if( lt[ e ].current < 0 ) then
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
    as Health ptr h
    as ECSComponent C_HEALTH
end type

constructor CollidableSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  require Position in p
  require Physics in ph
  require Dimensions in d
  require Collision in coll
  
  C_HEALTH = myComponents.getID( "health" )
  h = myComponents[ C_HEALTH ]
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
        '' Compute collision normal
        var vN = getCollisionNormal( ( a1.center - a2.center ), ph[ e1 ].vel, ph[ e2 ].vel )
        '' Compute minimum translation vector
        var mtv = collided( a1, a2, ph[ e1 ].vel, ph[ e2 ].vel )
        
        '' Adjust the position of the entities
        p[ e1 ].pos += mtv * 0.5f
        p[ e2 ].pos -= mtv * 0.5f
        
        '' Damage the entities in question if they have health. The damage taken will
        '' scale depending on the velocity of the collision and the size of the entities
        '' that collided.
        if( myComponents.hasComponent( e1, C_HEALTH ) ) then
          h[ e1 ].current -= vN.length * ( C_DAMAGE_SCALE * d[ e2 ].size )
        end if
        
        if( myComponents.hasComponent( e2, C_HEALTH ) ) then
          h[ e2 ].current -= vN.length * ( C_DAMAGE_SCALE * d[ e1 ].size )
        end if
      end if
    next
  next
end sub

type DestructibleSystem extends ECSSystem
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
    as Damaged ptr dmg
    
    as ECSComponent T_BULLET, T_DESTRUCTIBLE
end type

constructor DestructibleSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  has "trait:destructible"
  has "type:bullet"
  
  lt = has( "lifetime" )
  h = has( "health" )
  dmg = has( "damaged" )
  
  require Position in p
  require Dimensions in d
  
  prnt = myComponents[ "parent" ]
  
  T_BULLET = myComponents.getID( "type:bullet" )
  T_DESTRUCTIBLE = myComponents.getID( "trait:destructible" )
end constructor

destructor DestructibleSystem() : end destructor

sub DestructibleSystem.process( dt as double = 0.0d )
  '' We only want to process bullets and anything that can be damaged
  filter e as ECSEntity in processed like contains( e, T_BULLET ) in bullets
  filter e as ECSEntity in processed like contains( e, T_DESTRUCTIBLE ) in other
  
  var abb = BoundingCircle(), bbb = BoundingCircle()
  
  for each b as ECSEntity in bullets
    bbb.center = p[ b ].pos
    bbb.radius = d[ b ].size
    
    for each a as ECSEntity in other
      abb.center = p[ a ].pos
      abb.radius = d[ a ].size
      
      '' Make sure we don't damage ourselves with our own bullets
      if( a <> prnt[ b ].id andAlso bbb.overlapsWith( abb ) ) then
        '' Collided?
        dmg[ a ].value = true
        
        circle( p[ b ].pos.x, p[ b ].pos.y ), 15, BLUE, , , , f
        circle( p[ b ].pos.x, p[ b ].pos.y ), 10, WHITE, , , , f
        
        lt[ b ].current = 0.0f
        h[ a ].current -= 120.0f
        
        '' Did we destroy it?
        if( h[ a ].current < 0.0f ) then
          ECS.raiseEvent( EV_GAME_ENTITY_SHOT, _
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
  
  require Health in h
end constructor

destructor HealthSystem() : end destructor

sub HealthSystem.process( dt as double = 0.0d )
  var destroyed = UnorderedList( processed.count )
  
  for each e as ECSEntity in processed
    if( h[ e ].current < 0.0f ) then
      destroyed.add( e )
    end if
  next
  
  for each e as ECSEntity in destroyed
    ECS.raiseEvent( EV_GAME_ENTITY_DESTROYED, _
      GameEntityDestroyedEventArgs( e, -1, myEntities, myComponents ), @this )
    
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
    as ECSComponent T_ASTEROID
end type

constructor AsteroidDestroyedSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  ECS.registerListener( EV_GAME_ENTITY_DESTROYED, toHandler( event_gameEntityDestroyed ), @this )
  
  require Position in p
  require Dimensions in d
  
  T_ASTEROID = myComponents.getID( "type:asteroid" )
end constructor

destructor AsteroidDestroyedSystem()
  ECS.unregisterListener( EV_GAME_ENTITY_DESTROYED, toHandler( event_gameEntityDestroyed ), @this )
end destructor

sub AsteroidDestroyedSystem.event_gameEntityDestroyed( _
  sender as any ptr, e as GameEntityDestroyedEventArgs, receiver as AsteroidDestroyedSystem ptr )
  
  '' Was the destroyed entity an asteroid?
  if( e.c->hasComponent( e.destroyed, receiver->T_ASTEROID ) ) then
    var p = receiver->p[ e.destroyed ].pos
    var s = receiver->d[ e.destroyed ].size
    
    '' Break the asteroid into smaller pieces if it's a large one
    dim as single size = s * 0.25
    
    if( size >= 4.0f ) then
      for i as integer = 1 to 3
        newAsteroid( *e.e, *e.c, p, rndNormal() * ( 400.0f - size * 10.0f ), size )
      next
    end if
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
  
  ECS.registerListener( EV_GAME_ENTITY_SHOT, toHandler( event_gameEntityDestroyed ), @this )
  
  require Score in sc
end constructor

destructor ScoreSystem()
  ECS.unregisterListener( EV_GAME_ENTITY_SHOT, toHandler( event_gameEntityDestroyed ), @this )
end destructor

sub ScoreSystem.event_gameEntityDestroyed( _
  sender as any ptr, e as GameEntityDestroyedEventArgs, receiver as ScoreSystem ptr )
  
  '' TODO: wrap some macro up to simply this syntax...
  component( *e.c, component( *e.c, e.author, Parent ).id, Score ) _
    .value += roundUp( component( *e.c, e.destroyed, ScoreValue ).value, 10 )
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
  
  has "type:ship"
  
  require Position in p
  require Orientation in o
  require Dimensions in d
  require Appearance in a
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
    as AsteroidRenderData ptr ard
    as Damaged ptr dmg
end type

constructor AsteroidRenderSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  has "type:asteroid"
  
  require Position in p
  require Dimensions in d
  require Appearance in a
  require AsteroidRenderData in ard
  require Damaged in dmg
end constructor

destructor AsteroidRenderSystem() : end destructor

sub AsteroidRenderSystem.process( dt as double = 0.0d )
  for each e as ECSEntity in processed
    dim as ulong c = iif( dmg[ e ].value, rgb( 255, 0, 0 ), rgb( 255, 255, 255 ) )
    
    with p[ e ]
      pset( .pos.x + ard[ e ].points( 0 ).x, .pos.y + ard[ e ].points( 0 ).y ), c
      
      for i as integer = 1 to ard[ e ].faces - 1
        line -( .pos.x + ard[ e ].points( i ).x, .pos.y + ard[ e ].points( i ).y ), c
      next
      
      line -( .pos.x + ard[ e ].points( 0 ).x, .pos.y + ard[ e ].points( 0 ).y ), c
    end with
    
    dmg[ e ].value = false
  next
end sub

type BulletRenderSystem extends ECSSystem
  declare constructor( as ECSEntities, as ECSComponents )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Physics ptr ph
    as Lifetime ptr lt
    as Dimensions ptr d
    
    as long t
    as ulong c0 = rgb( 255, 0, 0 ), c1 = rgb( 0, 0, 255 )
end type

constructor BulletRenderSystem( e as ECSEntities, c as ECSComponents )
  base( e, c )
  
  has "type:bullet"
  
  require Position in p
  require Physics in ph
  require Lifetime in lt
  require Dimensions in d
end constructor

destructor BulletRenderSystem() : end destructor

sub BulletRenderSystem.process( dt as double = 0.0d )
  t += 10
  
  for each e as ECSEntity in processed
    dim as long a = remap( lt[ e ].current, 0, lt[ e ].max, 0, 255 )
    dim as long clr = t and 255
    
    with p[ e ]
      circle( .pos.x, .pos.y ), d[ e ].size, RGBlerp( t, c0, c1 )
      circle( .pos.x, .pos.y ), d[ e ].size - 1, rgba( 168, 228, 251, a )
      circle( .pos.x, .pos.y ), d[ e ].size - 2, rgba( t, t, t, a ), , , , f
    end with
  next
end sub

#endif
