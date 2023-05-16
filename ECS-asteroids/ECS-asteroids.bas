#include once "fbgame/fb-game.bi"
#include once "../fb-ecs.bi"

using FbGame

#include once "ECS-asteroids-commons.bi"
#include once "ECS-asteroids-components.bi"
#include once "ECS-asteroids-factories.bi"
#include once "ECS-asteroids-systems.bi"

Debug.toConsole()

Debug.print( "Creating entities and components..." )
  var myEntities = Entities(), myComponents = Components( myEntities )
Debug.print( "Done." )

Debug.print( "Registering components..." )
  registerComponent( myComponents, "position", Position )
  registerComponent( myComponents, "orientation", Orientation )
  registerComponent( myComponents, "physics", Physics )
  registerComponent( myComponents, "appearance", Appearance )
  registerComponent( myComponents, "dimensions", Dimensions )
  registerComponent( myComponents, "controls", Controls )
  registerComponent( myComponents, "health", Health )
  registerComponent( myComponents, "score", Score )
  registerComponent( myComponents, "speed", Speed )
  registerComponent( myComponents, "lifetime", Lifetime )
  registerComponent( myComponents, "ship", Ship )
  registerComponent( myComponents, "controlparameters", ControlParameters )
  registerComponent( myComponents, "collision", Collision )
  registerComponent( myComponents, "owner", Owner )
  
  myComponents.register( "type:ship" )
  myComponents.register( "type:asteroid" )
  myComponents.register( "type:bullet" )
Debug.print( "Done" )

/'
  Main code
'/
Game.init( 800, 600 )

'' Instantiate systems before creating entities
var s_lifetime = LifetimeSystem( myEntities, myComponents )
var s_renderShip = ShipRenderSystem( myEntities, myComponents )
var s_renderAsteroids = AsteroidRenderSystem( myEntities, myComponents )
var s_renderBullets = BulletRenderSystem( myEntities, myComponents )
var s_move = MovableSystem( myEntities, myComponents )
var s_control = ControllableSystem( myEntities, myComponents )
var s_collision = CollidableSystem( myEntities, myComponents )
var s_shoot = ShootableSystem( myEntities, myComponents )
var s_health = HealthSystem( myEntities, myComponents )
var s_destroyAsteroid = AsteroidDestroyedSystem( myEntities, myComponents )
var s_score = ScoreSystem( myEntities, myComponents )

'' Create entities
createPlayer( myEntities, myComponents )
createShip( myEntities, myComponents, myEntities.find( "player" ) )
createAsteroids( myEntities, myComponents, 30 )

dim as double dt, updateTime, updateTotal, renderTime, renderTotal, frameTime
dim as ulongint count

dim as Fb.Event ev

Debug.print( "Player ship ID: " & myEntities.find( "playership" ) )

do
  count += 1
  frameTime = updateTotal + renderTotal
  
  do while( screenEvent( @ev ) )
    Game.keyboard.onEvent( @ev )
  loop
  
  if( Game.keyboard.pressed( Fb.SC_R ) ) then
    var p = myEntities.find( "playership" )
    myComponents.removeComponent( p, "controls" )
  end if
  
  if( Game.keyboard.pressed( Fb.SC_A ) ) then
    var p = myEntities.find( "playership" )
    myComponents.addComponent( p, "controls" )
  end if
  
  updateTime = timer()
  
  '' Update
  s_lifetime.process( dt )
  s_health.process( dt )
  s_control.process( dt )
  s_move.process( dt )
  s_collision.process( dt )
  
  updateTime = timer() - updateTime
  updateTotal += updateTime
  
  '' Render
  dt = timer()
    renderTime = timer()
    cls()
      s_renderBullets.process()
      s_renderShip.process()
      s_renderAsteroids.process()
      s_shoot.process()
      
      ? "FPS: " & int( 1 / ( frameTime  / count ) )
      ? "Update: " & int( 1 / ( updateTotal / count ) ) & " (" & int( ( updateTotal / frameTime ) * 100 ) & "%)"
      ? "Render: " & int( 1 / ( renderTotal / count ) ) & " (" & int( ( renderTotal / frameTime ) * 100 ) & "%)" 
    flip()
    renderTime = timer() - renderTime
    renderTotal += renderTime
    
    sleep( 1, 1 )
  dt = timer() - dt
loop until( Game.keyboard.pressed( Fb.SC_ESCAPE ) )
