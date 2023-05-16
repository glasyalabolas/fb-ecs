#include once "fb-linkedlist.bi"

'' Type alias for event IDs
type as long EventID

'' Just a base type to allow covariant types
type EventArgs extends Object : end type

'' Signature for event handling subs
type as sub( as any ptr, as EventArgs, as any ptr = 0 ) EventHandler

'' Convenience macro to perform the covariant cast
#define toHandler( fp ) ( cast( EventHandler, @fp ) )

'' Internal table; no need to mess with this
type EventTableEntry
  as EventID eID
  as Fb.LinkedList listeners
  as long idx
end type

type EventRegister
  declare constructor( as EventHandler, as any ptr )
  
  as EventHandler handler
  as any ptr receiver
end type

constructor EventRegister( h as EventHandler, r as any ptr )
  handler = h : receiver = r
end constructor

type Events
  public:
    declare constructor()
    declare constructor( as long )
    declare destructor()
    
    declare function registerListener( as EventID, as EventHandler, as any ptr = 0 ) as boolean
    declare function unregisterListener( as EventID, as EventHandler ) as boolean
    declare sub raise( as EventID, as EventArgs, as any ptr = 0 )
  
  private:
    declare static function hash( as ulong ) as ulong
    
    declare function find( as EventID ) as EventTableEntry ptr
    
    as EventTableEntry _bucket( any )
    as long _entry( any ), _size, _count
end type

constructor Events()
  constructor( 256 )
end constructor

constructor Events( size as long )
  _size = iif( size < 16, 16, size )
  redim _bucket( 0 to _size - 1 )
  redim _entry( 0 to _size - 1 )
  
  for i as integer = 0 to _size - 1
    _entry( i ) = -1
  next
end constructor

destructor Events()
  for i as integer = 0 to _size - 1
  
  next
  
  erase( _bucket )
  erase( _entry )
end destructor

function Events.hash( x as ulong ) as ulong
  x = ( ( x shr 16 ) xor x ) * &h45d9f3b
  x = ( ( x shr 16 ) xor x ) * &h45d9f3b
  return( ( x shr 16 ) xor x )
end function

function Events.find( eID as EventID ) as EventTableEntry ptr
  dim as ulong h = hash( eID ) mod _size
  dim as long current = _entry( h )
  
  do while( current <> -1 )
    if( _bucket( current ).eID = eID ) then
      return( @_bucket( current ) )
    end if
    
    current = _bucket( current ).idx
  loop
  
  return( 0 )
end function

function Events.registerListener( eID as EventID, handler as EventHandler, receiver as any ptr = 0 ) as boolean
  var e = find( eID )
  
  if( e = 0 ) then
    '' Event isn't registered yet
    if( _count < _size ) then
      dim as ulong h = hash( eID ) mod _size
      
      _bucket( _count ).idx = _entry( h )
      _bucket( _count ).eID = eID
      _bucket( _count ).listeners.addLast( new EventRegister( handler, receiver ) )
      _entry( h ) = _count
      
      _count += 1
      
      return( true )
    end if
  else
    '' Event is already registered, just add the handler
    e->listeners.addLast( new EventRegister( handler, receiver ) )
    return( true )
  end if
  
  return( false )
end function

function Events.unregisterListener( eID as EventID, handler as EventHandler ) as boolean
  var e = find( eID )
  
  if( e <> 0 ) then
    var n = e->listeners.first
    
    do while( n <> 0 )
      if( cast( EventRegister ptr, n->item )->handler = handler ) then
        delete( cast( EventRegister ptr, e->listeners.remove( n ) ) )
        return( true )
      end if
      
      n = n->forward
    loop
  end if
  
  return( false )
end function

sub Events.raise( eID as EventID, p as EventArgs, sender as any ptr = 0 )
  var e = find( eID )
  
  if( e <> 0 ) then
    var n = e->listeners.first
    
    for i as integer = 0 to e->listeners.count - 1
      cast( EventRegister ptr, n->item )->handler( _
        sender, p, cast( EventRegister ptr, n->item )->receiver )
      
      n = n->forward 
    next
  end if
end sub
