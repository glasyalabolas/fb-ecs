#ifndef __ECS_ASTEROIDS_ENTITIES__
#define __ECS_ASTEROIDS_ENTITIES__

#macro ADD_COMPONENT( _mc_, _c_, _e_ )
  ( *cast( _c_ ptr, _mc_.addComponent( _e_, #_c_ ) ) )
#endmacro

function newShip( e as ECSEntities, c as ECSComponents, owner as ECSEntity ) as ECSEntity
  var pship = e.create( "playership" )
  
  asComponent( Position, c.addComponent( pship, "position" ) ) _
    .pos = Vec2( Game.playArea.width / 2, Game.playArea.height / 2 )

  asComponent( Orientation, c.addComponent( pship, "orientation" ) ) _
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
    .rateOfFire = 50.0f
  end with
  
  withComponent( Controls, c.addComponent( pship, "controls" ) )
    .forward = Fb.SC_UP
    .backward = Fb.SC_DOWN
    .rotateLeft = Fb.SC_LEFT
    .rotateRight = Fb.SC_RIGHT
    .fire = Fb.SC_SPACE
    .strafe = Fb.SC_LSHIFT
  end with
  
  asComponent( Collision, c.addComponent( pship, "collision" ) ) _
    .radius = 5.0f
  asComponent( Parent, c.addComponent( pship, "parent" ) ) _
    .id = owner
  
  c.addComponent( pship, "type:ship" )
  
  return( pship )
end function

function newPlayer( e as ECSEntities, c as ECSComponents, n as string ) as ECSEntity
  var player = e.create( n )
  
  asComponent( Health, c.addComponent( player, "health" ) ) _
    .value = 1000.0f
  asComponent( Score, c.addComponent( player, "score" ) ) _
    .value = 0
  
  return( player )
end function

function newAsteroid( e as ECSEntities, c as ECSComponents, p as Vec2, v as Vec2, s as single ) as ECSEntity
  var asteroid = e.create()
  
  ADD_COMPONENT( c, Position, asteroid ) _
    .pos = p
  'asComponent( Position, c.addComponent( asteroid, "position" ) ) _
  '  .pos = p
  
  with ADD_COMPONENT( c, Physics, asteroid )
    .vel = v
    .maxSpeed = 300.0f
  end with
  
  'withComponent( Physics, c.addComponent( asteroid, "physics" ) )
  '  .vel = v
  '  .maxSpeed = 300.0f
  'end with
  
  asComponent( Dimensions, c.addComponent( asteroid, "dimensions" ) ) _
    .size = s
  asComponent( Appearance, c.addComponent( asteroid, "appearance" ) ) _
    .color = RED
  asComponent( Health, c.addComponent( asteroid, "health" ) ) _
    .value = 5.0f * s
  asComponent( Collision, c.addComponent( asteroid, "collision" ) ) _
    .radius = s
  asComponent( ScoreValue, c.addComponent( asteroid, "scorevalue" ) ) _
    .value = 500 / s
  c.addComponent( asteroid, "type:asteroid" )
  
  return( asteroid )
end function

function newBullet( _
  e as ECSEntities, c as ECSComponents, p as Vec2, vel as Vec2, spd as single, lt as single, owner as ECSEntity ) as ECSEntity
  
  var bullet = e.create()
  
  asComponent( Position, c.addComponent( bullet, "position" ) ) _
    .pos = p
  
  withComponent( Physics, c.addComponent( bullet, "physics" ) )
    .vel = vel.normalized() * spd
    .maxSpeed = 500.0f
  end with
  
  asComponent( Dimensions, c.addComponent( bullet, "dimensions" ) ) _
    .size = 4.0f
  asComponent( Lifetime, c.addComponent( bullet, "lifetime" ) ) _
    .value = lt
  asComponent( Parent, c.addComponent( bullet, "parent" ) ) _
    .id = owner
  
  c.addComponent( bullet, "type:bullet" )
  
  return( bullet )
end function

sub createAsteroids( e as ECSEntities, c as ECSComponents, count as long )
  for i as integer = 1 to count
    dim as single size = rng( 8.0f, 40.0f )
    
    newAsteroid( e, c, rngWithin( Game.playArea ), _
      Vec2( rng( -1.0f, 1.0f ), rng( -1.0f, 1.0f ) ) * ( 200.0f - size * 5.0f ), size )
  next
end sub

#endif