#include once "fb-ecs.bi"

private function rng( aMin as double, aMax as double ) as double
  return( rnd() * ( aMax - aMin ) + aMin )
end function

type Position
  as single x, y
end type

type Size
  as single w, h
end type

type Appearance
  as ulong color
end type

type Physics
  as single dirX, dirY
end type

type Bounds
  as single x, y, w, h
end type

type Move extends System
  declare constructor( as Entities, as Components )
  declare virtual destructor() override
  
  declare sub process() override
  
  private:
    as Position ptr p
    as Physics ptr ph
end type

constructor Move( e as Entities, c as Components )
  base( e, c )
  
  p = requires( "position" )
  ph = requires( "physics" )
end constructor

destructor Move() : end destructor

sub Move.process()
  for i as integer = 0 to processed.count - 1
    dim as Entity e = processed[ i ]
    
    p[ e ].x += ph[ e ].dirX : p[ e ].y += ph[ e ].dirY
  next
end sub

type Render extends System
  declare constructor( as Entities, as Components )
  declare virtual destructor() override
  
  declare sub process() override
  
  private:
    as Position ptr p
    as Size ptr s
    as Appearance ptr app
end type

constructor Render( e as Entities, c as Components )
  base( e, c )
  
  p = requires( "position" )
  s = requires( "size" )
  app = requires( "appearance" )
end constructor

destructor Render() : end destructor

sub Render.process()
  for i as integer = 0 to processed.count - 1
    dim as Entity e = processed[ i ]
    dim as single hw = s[ e ].w / 2, hh = s[ e ].h / 2
    
    line( p[ e ].x - hw, p[ e ].y - hh ) - ( p[ e ].x + hw, p[ e ].y + hh ), app[ e ].color, bf
  next
end sub

type EnforceBounds extends System
  declare constructor( as Entities, as Components )
  declare destructor() override
  
  declare sub process() override
  
  private:
    as Position ptr p
    as Physics ptr ph
    as Bounds ptr b
end type

constructor EnforceBounds( e as Entities, c as Components )
  base( e, c )
  
  p = requires( "position" )
  ph = requires( "physics" )
  b = requires( "bounds" )
end constructor

destructor EnforceBounds() : end destructor

sub EnforceBounds.process()
  for i as integer = 0 to processed.count - 1
    dim as Entity e = processed[ i ]
    
    if( p[ e ].x < b[ e ].x ) then
      p[ e ].x = b[ e ].x
      ph[ e ].dirX = -ph[ e ].dirX
    end if
    
    if( p[ e ].x > b[ e ].w ) then
      p[ e ].x = b[ e ].w
      ph[ e ].dirX = -ph[ e ].dirX
    end if
    
    if( p[ e ].y < b[ e ].y ) then
      p[ e ].y = b[ e ].y
      ph[ e ].dirY = -ph[ e ].dirY
    end if
    
    if( p[ e ].y > b[ e ].h ) then
      p[ e ].y = b[ e ].h
      ph[ e ].dirY = -ph[ e ].dirY
    end if
  next
end sub

function createRectangle( _
  e as Entities, c as Components, _
  x as single, y as single, w as single, h as single, clr as ulong ) as Entity
  
  var r = e.create()
  
  with *cast( Position ptr, c.addComponent( r, "position" ) )
    .x = x : .y = y
  end with
  
  with *cast( Size ptr, c.addComponent( r, "size" ) )
    .w = w : .h = h
  end with
  
  with *cast( Appearance ptr, c.addComponent( r, "appearance" ) )
    .color = clr
  end with
  
  with *cast( Physics ptr, c.addComponent( r, "physics" ) )
    .dirX = rng( -1, 1 ) : .dirY = rng( -1, 1 )
  end with
  
  return( r )
end function

sub setBounds( e as Entity, c as Components, w as single, h as single )
  with *cast( Bounds ptr, c.addComponent( e, "bounds" ) )
    .x = 0 : .y = 0 : .w = w : .h = h
  end with
end sub

sub createRectangles( num as long, e as Entities, c as Components )
  for i as integer = 1 to num
    setBounds( createRectangle( e, c, 400, 300, rng( 25, 50 ), rng( 25, 50 ), _
      rnd() * &hffffff ), c, 800, 600 )
  next
end sub

var ent = Entities()
var cmp = Components()

cmp.register( "position", sizeof( Position ) )
cmp.register( "size", sizeof( Size ) )
cmp.register( "appearance", sizeof( Appearance ) )
cmp.register( "physics", sizeof( Physics ) )
cmp.register( "bounds", sizeof( Bounds ) )

var moveSystem = Move( ent, cmp )
var renderSystem = Render( ent, cmp )
var boundsSystem = EnforceBounds( ent, cmp )

screenRes( 800, 600, 32, 2 )
screenSet( 0, 1 )

randomize()

createRectangles( 500, ent, cmp )

dim as double t, updateTime, renderTime

do
  t = timer()
  moveSystem.process()
  boundsSystem.process()
  t = timer() - t
  updateTime = ( updateTime + t ) / 2
  
  t = timer()
  cls()
    renderSystem.process()
  
    ? "Update: " & int( 1 / updateTime )
    ? "Render: " & int( 1 / renderTime )
  flip()
  
  t = timer() - t
  renderTime = ( renderTime + t ) / 2
  
  sleep( 1, 1 )
loop until( len( inkey() ) )
