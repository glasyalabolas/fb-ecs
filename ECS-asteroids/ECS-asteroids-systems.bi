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

sub shoot( e as Entities, c as Components, _
  m as Movable, o as Orientable, ph as Physics, dt as double )
  
  '' Choose a random direction arc
  var vel = o.dir.rotated( rad( rng( -5.0f, 5.0f ) ) ).normalize()
  
  '' Spawn bullet
  createBullet( e, c, m.pos, vel, 500.0f, 50000.0f )
  
  '' Add a little backwards acceleration to the shooting entity
  '' when firing.
  'accelerate( ph, -o.dir.normalized() * 400.0f * dt )
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
        shoot( getEntities(), getComponents(), m[ e ], o[ e ], ph[ e ], dt )
      end if
      
      'if( Game.keyboard.repeated( .fire, params[ e ].rateOfFire ) ) then
      if( Game.keyboard.repeated( .fire, 1.0 ) ) then
        shoot( getEntities(), getComponents(), m[ e ], o[ e ], ph[ e ], dt )
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

type BulletRenderSystem extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process( as double = 0.0d ) override
  
  private:
    as Movable ptr m
    as Physics ptr ph
end type

constructor BulletRenderSystem( e as Entities, c as Components )
  base( e, c )
  
  requires( "type:bullet" )
  m = requires( "movable" )
  ph = requires( "physics" )
end constructor

destructor BulletRenderSystem() : end destructor

sub BulletRenderSystem.process( dt as double = 0.0d )
  for each e as Entity in processed
    var ep = m[ e ].pos - ( ph[ e ].vel.normalized() * 8 )
    
    line( m[ e ].pos.x, m[ e ].pos.y ) - ( ep.x, ep.y ), WHITE
    circle( m[ e ].pos.x, m[ e ].pos.y ), 3, RED, , , , f
  next
end sub
