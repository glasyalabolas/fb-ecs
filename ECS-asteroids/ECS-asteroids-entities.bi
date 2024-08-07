#ifndef __ECS_ASTEROIDS_ENTITIES__
#define __ECS_ASTEROIDS_ENTITIES__

/'
  These functions just create 'default' entities.
  In a sense, these are the archetypes of the entities you'll use.
  
  TODO: implement a mechanism to copy components, so you can cache and reuse these
    archetypes if you want.
'/
function newShip( e as ECSEntities, c as ECSComponents, parent as ECSEntity ) as ECSEntity
  var pship = e.create( "playership" )
  
  ADD_COMPONENT( c, Position, pship ) _
    .pos = Vec2( Game.playArea.width / 2, Game.playArea.height / 2 )
  ADD_COMPONENT( c, Orientation, pship ).dir = Vec2( 0.0, -1.0 )
  
  with ADD_COMPONENT( c, Physics, pship )
    .vel = Vec2( 0.0, 0.0 )
    .maxSpeed = 300.0f
  end with
  
  ADD_COMPONENT( c, Dimensions, pship ).size = 20.0f
  ADD_COMPONENT( c, Appearance, pship ).color = YELLOW
  
  with ADD_COMPONENT( c, ControlParameters, pship )
    .accel = 550.0f
    .turnSpeed = 360.0f
    .rateOfFire = 150.0f
  end with
  
  with ADD_COMPONENT( c, Controls, pship )
    .forward = Fb.SC_UP
    .backward = Fb.SC_DOWN
    .rotateLeft = Fb.SC_LEFT
    .rotateRight = Fb.SC_RIGHT
    .fire = Fb.SC_SPACE
    .strafe = Fb.SC_LSHIFT
  end with
  
  with ADD_COMPONENT( c, Health, pship )
    .max = 400.0f
    .current = .max
  end with
  
  ADD_COMPONENT( c, Collision, pship ).radius = 5.0f
  ADD_COMPONENT( c, Parent, pship ).id = parent
  
  '' And this is how you add traits to the entities (managed by the component system)
  c.addComponent( pship, "type:ship" )
  c.addComponent( pship, "trait:destructible" )
  
  return( pship )
end function

function newPlayer( e as ECSEntities, c as ECSComponents, n as string ) as ECSEntity
  var player = e.create( n )
  
  ADD_COMPONENT( c, Score, player ).value = 0
  
  return( player )
end function

function newAsteroid( e as ECSEntities, c as ECSComponents, p as Vec2, v as Vec2, s as single ) as ECSEntity
  var asteroid = e.create()
  
  ADD_COMPONENT( c, Position, asteroid ).pos = p
  
  with ADD_COMPONENT( c, Physics, asteroid )
    .vel = v
    .maxSpeed = 200.0f
  end with
  
  ADD_COMPONENT( c, Dimensions, asteroid ).size = s
  ADD_COMPONENT( c, Appearance, asteroid ).color = RED
  
  with ADD_COMPONENT( c, Health, asteroid )
    .max = 20.0f * s
    .current = .max
  end with
  
  ADD_COMPONENT( c, Collision, asteroid ).radius = s
  ADD_COMPONENT( c, ScoreValue, asteroid ).value = 500 / s
  
  with ADD_COMPONENT( c, AsteroidRenderData, asteroid )
    .faces = rng( 8, 14 )
    redim .points( 0 to .faces - 1 )
    
    dim as single iFaces = 1.0f / .faces
    
    for i as integer = 0 to .faces - 1
      .points( i ) = Polar( rng( s * 0.5f, s ), rad( ( 360.0f * iFaces ) * i ) )
    next
  end with
  
  '' You can add a simple component (like a boolean) like this if you don't need to
  '' initialize it.
  c.addComponent( asteroid, "damaged" )
  
  c.addComponent( asteroid, "type:asteroid" )
  c.addComponent( asteroid, "trait:destructible" )
  
  return( asteroid )
end function

function newBullet( e as ECSEntities, c as ECSComponents, _
  p as Vec2, vel as Vec2, spd as single, lt as single, owner as ECSEntity ) as ECSEntity
  
  var bullet = e.create()
  
  ADD_COMPONENT( c, Position, bullet ).pos = p
  
  with ADD_COMPONENT( c, Physics, bullet )
    .vel = vel.normalized() * spd
    .maxSpeed = 500.0f
  end with
  
  ADD_COMPONENT( c, Dimensions, bullet ).size = 5.0f
  
  with ADD_COMPONENT( c, Lifetime, bullet )
    .max = lt
    .current = .max
  end with
  
  ADD_COMPONENT( c, Parent, bullet ).id = owner
  
  c.addComponent( bullet, "type:bullet" )
  
  return( bullet )
end function

#endif
