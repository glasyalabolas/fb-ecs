function createShip( e as Entities, c as Components ) as Entity
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
    .rateOfFire = 100.0f
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

function createAsteroid( e as Entities, c as Components ) as Entity
  var asteroid = e.create()
  
  dim as single size = rng( 8.0f, 40.0f )
  
  asComponent( Position, c.addComponent( asteroid, "position" ) ) _
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
    .value = 10.0f * size
  asComponent( Collision, c.addComponent( asteroid, "collision" ) ) _
    .radius = size
  
  c.addComponent( asteroid, "type:asteroid" )
  
  return( asteroid )
end function

sub createAsteroids( e as Entities, c as Components, count as long )
  for i as integer = 1 to count
    createAsteroid( e, c )
  next
end sub

function createBullet( e as Entities, c as Components, p as Vec2, vel as Vec2, spd as single, lt as single ) as Entity
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
  
  c.addComponent( bullet, "type:bullet" )
  
  return( bullet )
end function
