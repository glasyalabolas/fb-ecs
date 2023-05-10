#include once "fb-ecs.bi"

private function rng( aMin as double, aMax as double ) as double
  return( rnd() * ( aMax - aMin ) + aMin )
end function

type Position
  as single x, y
end type

var ent = Entities()
var cmp = Components()

registerComponent( cmp, "position", Position )

var player = ent.create( "player" )

? player

? ent.find( "player" )

'screenRes( 800, 600, 32, 2 )
'screenSet( 0, 1 )

'randomize()

sleep()
