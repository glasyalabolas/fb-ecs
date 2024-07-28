#include once "fbgame/fb-game.bi"
#include once "../fb-ecs.bi"

using FbGame

#include once "ECS-asteroids-commons.bi"
#include once "ECS-asteroids-components.bi"
#include once "ECS-asteroids-entities.bi"
#include once "ECS-asteroids-systems.bi"

#define ECS_DEBUG_ON

Debug.toConsole()

Debug.print( "Creating entities and components..." )
  var myEntities = ECSEntities(), myComponents = ECSComponents( myEntities )
Debug.print( "Done." )

Debug.print( "Registering components..." )
  register Position in myComponents
  register Orientation in myComponents
  register Physics in myComponents
  register Appearance in myComponents
  register Dimensions in myComponents
  register Controls in myComponents
  register Health in myComponents
  register Score in myComponents
  register ScoreValue in myComponents
  register Speed in myComponents
  register Lifetime in myComponents
  register Ship in myComponents
  register ControlParameters in myComponents
  register Collision in myComponents
  register Parent in myComponents
  register AsteroidRenderData in myComponents
  register Damaged in myComponents
  
  /'
    Traits are like components, in the sense that they 'define' an archetype. However, unlike them,
    they are used for such things as flags (ie 'is this even destructible?'), so that systems might
    use to discriminate the entities they need to process based on components.
    
    Of course, like components, you can add or remove them at will, and the systems will update
    themselves appropriately and stop processing those entities.
  '/
  trait "type:ship" in myComponents
  trait "type:asteroid" in myComponents
  trait "type:bullet" in myComponents
  trait "trait:destructible" in myComponents
Debug.print( "Done" )

Debug.print( myComponents.getDebugInfo() )

'' Just a helper function to create asteroids in the playfield
sub createAsteroids( e as ECSEntities, c as ECSComponents, count as long )
  for i as integer = 1 to count
    dim as single size = rng( 16.0f, 80.0f )
    
    newAsteroid( e, c, rngWithin( Game.playArea ), _
      Vec2( rng( -1.0f, 1.0f ), rng( -1.0f, 1.0f ) ) * ( 200.0f - size * 5.0f ), size )
  next
end sub

/'
  Main code
'/
Game.init( 800, 600 )

'' Instantiate systems before creating entities
Debug.print( "Instantiating systems..." )
  _DEBUG var s_lifetime = LifetimeSystem( myEntities, myComponents )
  _DEBUG var s_renderShip = ShipRenderSystem( myEntities, myComponents )
  _DEBUG var s_renderAsteroids = AsteroidRenderSystem( myEntities, myComponents )
  _DEBUG var s_renderBullets = BulletRenderSystem( myEntities, myComponents )
  _DEBUG var s_move = MovableSystem( myEntities, myComponents )
  _DEBUG var s_control = ControllableSystem( myEntities, myComponents )
  _DEBUG var s_collision = CollidableSystem( myEntities, myComponents )
  _DEBUG var s_destr = DestructibleSystem( myEntities, myComponents )
  _DEBUG var s_health = HealthSystem( myEntities, myComponents )
  _DEBUG var s_destroyAsteroid = AsteroidDestroyedSystem( myEntities, myComponents )
  _DEBUG var s_score = ScoreSystem( myEntities, myComponents )
Debug.print( "Done." )

'' Create entities
Debug.print( "Creating entities..." )
  _DEBUG var player = newPlayer( myEntities, myComponents, "player" )
  _DEBUG var ship = newShip( myEntities, myComponents, player )
  _DEBUG createAsteroids( myEntities, myComponents, 15 )
Debug.print( "Done." )

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
      s_destr.process()
      
      ? "FPS: " & int( 1 / ( frameTime  / count ) )
      ? "Score: " & component( myComponents, player, Score ).value
      ? "Health: " & component( myComponents, ship, Health ).current 
      ? "Update: " & int( 1 / ( updateTotal / count ) ) & " (" & int( ( updateTotal / frameTime ) * 100 ) & "%)"
      ? "Render: " & int( 1 / ( renderTotal / count ) ) & " (" & int( ( renderTotal / frameTime ) * 100 ) & "%)" 
    flip()
    
    renderTime = timer() - renderTime
    renderTotal += renderTime
    
    sleep( 1, 1 )
  dt = timer() - dt
loop until( Game.keyboard.pressed( Fb.SC_ESCAPE ) )
