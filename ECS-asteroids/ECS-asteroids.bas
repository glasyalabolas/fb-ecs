#include once "fbgame/fb-game.bi"
#include once "../fb-ecs.bi"

using FbGame

#include once "ECS-asteroids-commons.bi"
#include once "ECS-asteroids-components.bi"
#include once "ECS-asteroids-factories.bi"
#include once "ECS-asteroids-systems.bi"

Debug.toConsole()

Debug.print( "Creating entities and components..." )
  var AEntities = Entities(), AComponents = Components( AEntities )
Debug.print( "Done." )

Debug.print( "Registering components..." )
  registerComponent( AComponents, "position", Position )
  registerComponent( AComponents, "orientation", Orientation )
  registerComponent( AComponents, "physics", Physics )
  registerComponent( AComponents, "appearance", Appearance )
  registerComponent( AComponents, "dimensions", Dimensions )
  registerComponent( AComponents, "controls", Controls )
  registerComponent( AComponents, "health", Health )
  registerComponent( AComponents, "score", Score )
  registerComponent( AComponents, "speed", Speed )
  registerComponent( AComponents, "lifetime", Lifetime )
  registerComponent( AComponents, "ship", Ship )
  registerComponent( AComponents, "controlparameters", ControlParameters )
  registerComponent( AComponents, "collision", Collision )
  
  AComponents.register( "type:ship" )
  AComponents.register( "type:asteroid" )
  AComponents.register( "type:bullet" )
Debug.print( "Done" )

/'
  Main code
'/
Game.init( 800, 600 )

'' Instantiate systems before creating entities
var s_lifetime = LifetimeSystem( AEntities, AComponents )
var s_renderShip = ShipRenderSystem( AEntities, AComponents )
var s_renderAsteroids = AsteroidRenderSystem( AEntities, AComponents )
var s_renderBullets = BulletRenderSystem( AEntities, AComponents )
var s_move = MovableSystem( AEntities, AComponents )
var s_control = ControllableSystem( AEntities, AComponents )
var s_collision = CollidableSystem( Aentities, AComponents )
var s_shoot = ShootableSystem( AEntities, AComponents )
var s_health = HealthSystem( AEntities, AComponents )
var s_destroyAsteroid = AsteroidDestroyedSystem( AEntities, AComponents )
var s_score = ScoreSystem( AEntities, AComponents )

'' Create entities
createPlayer( AEntities, AComponents )
createAsteroids( AEntities, AComponents, 30 )

dim as double dt, updateTime, updateTotal, renderTime, renderTotal, frameTime
dim as ulongint count

dim as Fb.Event ev

do
  count += 1
  frameTime = updateTotal + renderTotal
  
  do while( screenEvent( @ev ) )
    Game.keyboard.onEvent( @ev )
  loop
  
  if( Game.keyboard.pressed( Fb.SC_R ) ) then
    var p = AEntities.find( "playership" )
    AComponents.removeComponent( p, "controls" )
  end if
  
  if( Game.keyboard.pressed( Fb.SC_A ) ) then
    var p = AEntities.find( "playership" )
    AComponents.addComponent( p, "controls" )
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
