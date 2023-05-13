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
registerComponent( AComponents, "ship", Ship )
registerComponent( AComponents, "controlparameters", ControlParameters )
registerComponent( AComponents, "collidable", Collidable )

AComponents.register( "type:ship" )
AComponents.register( "type:asteroid" )
AComponents.register( "type:bullet" )

Debug.print( "Done" )

#macro debugComponent( _n_ )
  Debug.print( _n_ & ": " & AComponents.getID( _n_ ) )
#endmacro

Debug.print( "Components:" )
debugComponent( "movable" )
debugComponent( "orientable" )
debugComponent( "physics" )
debugComponent( "appearance" )
debugComponent( "dimensions" )
debugComponent( "controllable" )
debugComponent( "health" )
debugComponent( "score" )
debugComponent( "speed" )
debugComponent( "lifetime" )
debugComponent( "collidable" )
debugComponent( "ship" )
debugComponent( "controlparameters" )
debugComponent( "collidable" )

/'
  Main code
'/
Game.init( 800, 600 )

'' Instantiate systems before creating entities
var lt = LifetimeSystem( AEntities, AComponents )
var r = ShipRenderSystem( AEntities, AComponents )
var ar = AsteroidRenderSystem( AEntities, AComponents )
var m = MovableSystem( AEntities, AComponents )
var ctrl = ControllableSystem( AEntities, AComponents )
var br = BulletRenderSystem( AEntities, AComponents )
var coll = CollidableSystem( Aentities, AComponents )

createAsteroids( AEntities, AComponents, 50 )
createPlayer( AEntities, AComponents )

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
    AComponents.removeComponent( p, "controllable" )
  end if
  
  if( Game.keyboard.pressed( Fb.SC_A ) ) then
    var p = AEntities.find( "playership" )
    AComponents.addComponent( p, "controllable" )
  end if
  
  updateTime = timer()
  
  '' Update
  ctrl.process( dt )
  m.process( dt )
  lt.process( dt )
  coll.process( dt )
  
  updateTime = timer() - updateTime
  updateTotal += updateTime
  
  '' Render
  dt = timer()
    renderTime = timer()
    cls()
      br.process()
      r.process()
      ar.process()
      
      ? "FPS: " & int( 1 / ( frameTime  / count ) )
      ? "Update: " & int( 1 / ( updateTotal / count ) ) & " (" & int( ( updateTotal / frameTime ) * 100 ) & "%)"
      ? "Render: " & int( 1 / ( renderTotal / count ) ) & " (" & int( ( renderTotal / frameTime ) * 100 ) & "%)" 
      ? "Lifetime is processing: " & lt.processed.count & " entities."
      ? "Collidable is processing: " & coll.processed.count & " entities."
    flip()
    renderTime = timer() - renderTime
    renderTotal += renderTime
    
    sleep( 1, 1 )
  dt = timer() - dt
loop until( Game.keyboard.pressed( Fb.SC_ESCAPE ) )
