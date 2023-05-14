sub move( m as Position, p as Physics, dt as double )
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
    as Position ptr p
    as Physics ptr ph
end type

constructor MovableSystem( e as Entities, c as Components )
  base( e, c )
  
  p = requires( "position" )
  ph = requires( "physics" )
end constructor

destructor MovableSystem() : end destructor

sub MovableSystem.process( dt as double = 0.0d )
  for each e as Entity in processed
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

sub shoot( e as Entities, c as Components, _
  m as Position, o as Orientation, ph as Physics, dt as double )
  
  '' Choose a random direction arc
  var vel = o.dir.rotated( rad( rng( -3.0f, 3.0f ) ) ).normalize()
  
  '' Spawn bullet
  createBullet( e, c, m.pos, vel, 500.0f, 2000.0f )
  
  '' Add a little backwards acceleration to the shooting entity
  '' when firing.
  accelerate( ph, -o.dir.normalized() * 400.0f * dt )
end sub

type ControllableSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Controls ptr ctrl
    as ControlParameters ptr params
    as Position ptr p
    as Orientation ptr o
    as Physics ptr ph
end type

constructor ControllableSystem( e as Entities, c as Components )
  base( e, c )
  
  ctrl = requires( "controls" )
  params = requires( "controlparameters" )
  p = requires( "position" )
  o = requires( "orientation" )
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
        shoot( getEntities(), getComponents(), p[ e ], o[ e ], ph[ e ], dt )
      end if
      
      if( Game.keyboard.repeated( .fire, params[ e ].rateOfFire ) ) then
        shoot( getEntities(), getComponents(), p[ e ], o[ e ], ph[ e ], dt )
      end if
    end with
  next
end sub

type LifetimeSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d )
  
  private:
    as Lifetime ptr lt
end type

constructor LifetimeSystem( e as Entities, c as Components )
  base( e, c )
  
  lt = requires( "lifetime" )
end constructor

destructor LifetimeSystem() : end destructor

sub LifetimeSystem.process( dt as double = 0.0d )
  var deleted = UnorderedList( processed.count )
  
  for each e as Entity in processed
    lt[ e ].value -= 1000.0f * dt
    
    if( lt[ e ].value < 0 ) then
      deleted.add( e )
    end if
  next
  
  for i as integer = 0 to deleted.count - 1
    getEntities().destroy( deleted[ i ] )
  next
end sub

type CollidableSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Physics ptr ph
    as Dimensions ptr d
    as Collision ptr coll
end type

constructor CollidableSystem( e as Entities, c as Components )
  base( e, c )
  
  p = requires( "position" )
  ph = requires( "physics" )
  d = requires( "dimensions" )
  coll = requires( "collision" )
end constructor

destructor CollidableSystem() : end destructor

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

sub CollidableSystem.process( dt as double = 0.0d )
  var a1 = BoundingCircle()
  var a2 = BoundingCircle()
  
  for i as integer = 0 to processed.count - 1
    dim as Entity e1 = processed[ i ]
    
    a1.center = p[ e1 ].pos
    a1.radius = coll[ e1 ].radius
    
    for j as integer = i + 1 to processed.count - 1
      dim as Entity e2 = processed[ j ]
      
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

type ShootableSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Collision ptr coll
    as Dimensions ptr d
    as Lifetime ptr lt
    as Health ptr h
end type

constructor ShootableSystem( e as Entities, c as Components )
  base( e, c )
  
  has( "type:asteroid" )
  has( "type:bullet" )
  
  lt = has( "lifetime" )
  h = has( "health" )
  p = requires( "position" )
  d = requires( "dimensions" )
end constructor

destructor ShootableSystem() : end destructor

sub ShootableSystem.process( dt as double = 0.0d )
  var bullets = UnorderedList( processed.count )
  
  for each e as Entity in processed
    if( contains( e, "type:bullet" ) ) then
      bullets.add( e )
    end if
  next
  
  var asteroids = UnorderedList( processed.count )
  
  for each e as Entity in processed
    if( contains( e, "type:asteroid" ) ) then
      asteroids.add( e )
    end if
  next
  
  var abb = BoundingCircle(), bbb = BoundingCircle()
  
  for each b as Entity in bullets
    bbb.center = p[ b ].pos
    bbb.radius = d[ b ].size
    
    for each a as Entity in asteroids
      abb.center = p[ a ].pos
      abb.radius = d[ a ].size
      
      if( bbb.overlapsWith( abb ) ) then
        '' Collided
        circle( abb.center.x, abb.center.y ), d[ a ].size, rgb( 0, 0, 255 ), , , , f
        
        lt[ b ].value = 0.0f
        h[ a ].value -= 30.0f
      end if 
    next
  next
end sub

type HealthSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d )
  
  private:
    as Health ptr h
end type

constructor HealthSystem( e as Entities, c as Components )
  base( e, c )
  
  h = requires( "health" )
end constructor

destructor HealthSystem() : end destructor

sub HealthSystem.process( dt as double = 0.0d )
  var destroyed = UnorderedList( processed.count )
  
  for each e as Entity in processed
    if( h[ e ].value < 0.0f ) then
      destroyed.add( e )
    end if
  next
  
  for each e as Entity in destroyed
    getEntities().destroy( e )
  next
end sub

type ShipRenderSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Orientation ptr o
    as Dimensions ptr d
    as Appearance ptr a
end type

constructor ShipRenderSystem( e as Entities, c as Components )
  base( e, c )
  
  requires( "type:ship" )
  p = requires( "position" ) 
  o = requires( "orientation" )
  d = requires( "dimensions" )
  a = requires( "appearance" )
end constructor

destructor ShipRenderSystem() : end destructor

sub ShipRenderSystem.process( dt as double = 0.0d )
  for each e as Entity in processed
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

type AsteroidRenderSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Dimensions ptr d
    as Appearance ptr a
end type

constructor AsteroidRenderSystem( e as Entities, c as Components )
  base( e, c )
  
  requires( "type:asteroid" )
  p = requires( "position" )
  d = requires( "dimensions" )
  a = requires( "appearance" )
end constructor

destructor AsteroidRenderSystem() : end destructor

sub AsteroidRenderSystem.process( dt as double = 0.0d )
  for each e as Entity in processed
    with p[ e ]
      circle( .pos.x, .pos.y ), d[ e ].size, a[ e ].color, , , , f
    end with
  next
end sub

type BulletRenderSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Position ptr p
    as Physics ptr ph
end type

constructor BulletRenderSystem( e as Entities, c as Components )
  base( e, c )
  
  requires( "type:bullet" )
  p = requires( "position" )
  ph = requires( "physics" )
end constructor

destructor BulletRenderSystem() : end destructor

sub BulletRenderSystem.process( dt as double = 0.0d )
  for each e as Entity in processed
    with p[ e ]
      circle( .pos.x, .pos.y ), 4, BLUE
      circle( .pos.x, .pos.y ), 3, rgb( 168, 228, 251 )
      circle( .pos.x, .pos.y ), 2, WHITE, , , , f
    end with
  next
end sub
