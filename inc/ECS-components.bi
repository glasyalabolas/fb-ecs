#ifndef __ECS_COMPONENTS__
#define __ECS_COMPONENTS__

type as string DATA_BUFFER
type as long ComponentID

type ComponentTableEntry
  as string name
  as ComponentID id
  as DATA_BUFFER value
  as long idx
  as uinteger size
end type

type ComponentChangedEventArgs extends EventArgs
  declare constructor( as Entity, as ComponentID )
  
  as Entity eID
  as ComponentID cID
end type

constructor ComponentChangedEventArgs( e as Entity, c as ComponentID )
  eID = e : cID = c
end constructor

/'
  Component map
  
  It contains all the registered components for all entities, allocated as a
  generic buffer, in a hash table.
  The table is indexed by component ID (which is in turn the index into the
  hash table bucket), and the entity ID is then used to find the corresponding
  index into the component buffer.
'/
type Components extends Object
  public:
    declare constructor()
    declare destructor()
    
    declare operator []( as ComponentID ) as any ptr
    declare operator []( as string ) as any ptr
    
    declare function register( as string, as uinteger ) as ComponentID
    declare function register( as string ) as ComponentID
    declare function find( as string ) as ComponentID
    declare function getName( as ComponentID ) as string
    declare function getComponent( as Entity, as ComponentID ) as any ptr
    declare function getComponent( as Entity, as string ) as any ptr
    declare function addComponent( as Entity, as ComponentID ) as any ptr
    declare function addComponent( as Entity, as string ) as any ptr
    declare function removeComponent( as Entity, as ComponentID ) as boolean
    declare function removeComponent( as Entity, as string ) as boolean
    
    declare function hasComponent( as Entity, as ComponentID ) as boolean
  
  private:
    as ComponentTableEntry _components( 0 to ECS_MAX_COMPONENTS - 1 )
    as long _index( 0 to ECS_MAX_COMPONENTS - 1 )
    as long _count
    as boolean _componentMap( 0 to ECS_MAX_ENTITIES - 1, 0 to ECS_MAX_COMPONENTS - 1 )
end type

constructor Components()
  for i as integer = 0 to ECS_MAX_COMPONENTS - 1
    _index( i ) = -1
  next
end constructor

destructor Components()
  erase( _components )
  erase( _index )
  erase( _componentMap )
end destructor

operator Components.[]( id as ComponentID ) as any ptr
  return( cast( ubyte ptr, strptr( _components( id ).value ) ) )
end operator

operator Components.[]( n as string ) as any ptr
  dim as ComponentID id = find( n )
  
  return( cast( ubyte ptr, strptr( _components( id ).value ) ) )
end operator

function Components.find( k as string ) as ComponentID
  dim as ulong h = hashstr( k ) mod ECS_MAX_COMPONENTS
  dim as long current = _index( h )
  
  do while( current <> -1 )
    if( _components( current ).name = k ) then
      return( _components( current ).id )
    end if
    
    current = _components( current ).idx
  loop
  
  return( -1 )
end function

function Components.getName( c as ComponentID ) as string
  return( _components( c ).name )
end function

function Components.register( n as string, s as uinteger ) as ComponentID
  if( _count < ECS_MAX_COMPONENTS ) then
    dim as long id = _count
    dim as ulong h = hashstr( n ) mod ECS_MAX_COMPONENTS
    
    with _components( _count )
      .idx = _index( h )
      .id = id
      .name = n
      .value = string( s * ECS_MAX_ENTITIES, chr( 0 ) )
      .size = s
    end with
    
    _index( h ) = id
    _count += 1
    
    return( id )
  end if
  
  return( -1 )
end function

/'
  This method registers a 'null component' that can be added to entities
  but it shouldn't be indexed as a normal one.
  
  Why use it, then? Turns out that an ECS architecture doesn't have the
  concept of 'types', so systems will happily process any entity that has
  the required components.
  Certain systems (such as the ones that do rendering), this is important,
  as they frequently operate on entities that need the same set of
  components, but you have no way to discriminate them. This means that
  you might end up with two rendering systems that require the same
  components to render different things, and the net result is that *both*
  systems will render, say, a player *and* an enemy to the same entity.
  
  This way you can register void components that act as 'types' of sorts,
  and have the systems that should apply to specific sets of components
  require them:
  
  myComponentsInstance.register( "type:player" )
  myComponentsInstance.register( "type:enemy" )
  
  constructor PlayerRenderingSystem()
    requires( "type:player" )
    ...
  end constructor
  
  constructor EnemyRenderingSystem()
    requires( "type:enemy" )
    ...
  end constructor
  
  You can also use them as 'flag' components, without implementing a
  proper boolean component. These components can be added, and removed
  as usual, but not checked nor indexed as regular components.
  Components declared in this way allocate no memory.
'/
function Components.register( n as string ) as ComponentID
  return( register( n, 0 ) )
end function

function Components.getComponent( e as Entity, c as ComponentID ) as any ptr
  return( cast( ubyte ptr, strptr( _components( c ).value ) ) + e * _components( c ).size )
end function

function Components.getComponent( e as Entity, c as string ) as any ptr
  return( getComponent( e, find( c ) ) )
end function

function Components.addComponent( e as Entity, c as ComponentID ) as any ptr
  if( _componentMap( e, c ) = false ) then
    _componentMap( e, c ) = true
    ECS.raiseEvent( EV_COMPONENTADDED, ComponentChangedEventArgs( e, c ) )
  end if
  
  return( cast( ubyte ptr, strptr( _components( c ).value ) ) + e * _components( c ).size )
end function

function Components.addComponent( e as Entity, c as string ) as any ptr
  return( addComponent( e, find( c ) ) )
end function

function Components.removeComponent( e as Entity, c as ComponentID ) as boolean
  if( _componentMap( e, c ) = true ) then
    _componentMap( e, c ) = false
    ECS.raiseEvent( EV_COMPONENTREMOVED, ComponentChangedEventArgs( e, c ) )
    
    return( true )
  end if
  
  return( false )
end function

function Components.removeComponent( e as Entity, c as string ) as boolean
  return( removeComponent( e, find( c ) ) )
end function

function Components.hasComponent( e as Entity, c as ComponentID ) as boolean
  return( _componentMap( e, c ) )
end function

'' Convenience macro to register components
#macro registerComponent( _cmp_, _n_, _c_ )
  _cmp_.register( _n_, sizeof( _c_ ) )
#endmacro

#endif
