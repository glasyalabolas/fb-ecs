#ifndef __FB_ECS_COMPONENTS__
#define __FB_ECS_COMPONENTS__

#include once "fb-hashtable.bi"

const as long INVALID_COMPONENT = -1
const as long COMPONENT_NOT_FOUND = -2

type ComponentTableEntry
  as ComponentID id
  as uinteger size
  as DATA_BUFFER value
  as string name
end type

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
    declare constructor( as Entities )
    declare destructor()
    
    declare operator []( as ComponentID ) as any ptr
    declare operator []( as string ) as any ptr
    
    declare function register( as string, as uinteger ) as ComponentID
    declare function register( as string ) as ComponentID
    declare function getID( as string ) as ComponentID
    declare function getName( as ComponentID ) as string
    declare function getComponent( as Entity, as ComponentID ) as any ptr
    declare function getComponent( as Entity, as string ) as any ptr
    declare function addComponent( as Entity, as ComponentID ) as any ptr
    declare function addComponent( as Entity, as string ) as any ptr
    declare function removeComponent( as Entity, as ComponentID ) as boolean
    declare function removeComponent( as Entity, as string ) as boolean
    declare function hasComponent( as Entity, as ComponentID ) as boolean
    declare function hasComponent( as Entity, as string ) as boolean
    
    declare function getDebugInfo() as string
    
  private:
    declare static sub components_entityDestroyed( _
      as any ptr, as EntityChangedEventArgs, as Components ptr )
    
    as ComponentTableEntry _components( any )
    as boolean _componentMap( any, any )
    as long _componentTable( any, any )
    as long _componentCount( any )
    
    as Fb.HashTable ptr _hashTable
    
    as Entities ptr _entities
    as long _count
end type

constructor Components( e as Entities )
  redim _components( 0 to ECS_MAX_COMPONENTS - 1 )
  redim _componentMap( 0 to ECS_MAX_ENTITIES - 1, 0 to ECS_MAX_COMPONENTS - 1 )
  redim _componentTable( 0 to ECS_MAX_ENTITIES - 1, 0 to ECS_MAX_COMPONENTS - 1 )
  redim _componentCount( 0 to ECS_MAX_ENTITIES - 1 )
  
  _entities = @e
  
  ECS.registerListener( EV_ENTITYDESTROYED, toHandler( Components.components_entityDestroyed ), @this )
  
  _hashTable = new Fb.HashTable()
end constructor

destructor Components()
  ECS.unregisterListener( EV_ENTITYDESTROYED, toHandler( Components.components_entityDestroyed ), @this )
  
  erase( _components )
  erase( _componentMap )
  erase( _componentTable )
  erase( _componentCount )
  
  delete( _hashTable )
end destructor

operator Components.[]( id as ComponentID ) as any ptr
  return( cast( ubyte ptr, strptr( _components( id ).value ) ) )
end operator

operator Components.[]( n as string ) as any ptr
  dim as ComponentID id = getID( n )
  
  return( cast( ubyte ptr, strptr( _components( id ).value ) ) )
end operator

function Components.getDebugInfo() as string
  dim as string s
  
  dim as uinteger sum
  
  for i as integer = 0 to _count - 1
    sum += _components( i ).size * ECS_MAX_ENTITIES
  next
  
  s &= "** Components Info **" & chr( 13, 10 )
  s &= "Components registered: " & _count & chr( 13, 10 )
  s &= "Memory (bytes): " & sum & chr( 13, 10 )
  
  for i as integer = 0 to _count - 1
    s &= _components( i ).id & ": " & _components( i ).name & " (" & _components( i ).size & ")" & chr( 13, 10 )
  next
  
  return( s )
end function

function Components.getID( n as string ) as ComponentID
  dim as ComponentTableEntry ptr entry = _hashTable->find( n )
  
  return( iif( entry, entry->id, COMPONENT_NOT_FOUND ) )
end function

function Components.getName( c as ComponentID ) as string
  return( _components( c ).name )
end function

function Components.register( n as string, s as uinteger ) as ComponentID
  if( _count < ECS_MAX_COMPONENTS ) then
      dim as long id = _count
      
      with _components( _count )
        .id = id
        .name = n
        .value = string( s * ECS_MAX_ENTITIES, chr( 0 ) )
        .size = s
        
        _hashTable->add( .name, @_components( id ) )
      end with
      
      _count += 1
      
      return( id )
  end if
  
  return( INVALID_COMPONENT )
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
  return( getComponent( e, getID( c ) ) )
end function

function Components.addComponent( e as Entity, c as ComponentID ) as any ptr
  if( _componentMap( e, c ) = false ) then
    _componentMap( e, c ) = true
    _componentTable( e, _componentCount( e ) ) = c
    _componentCount( e ) += 1
    
    ECS.raiseEvent( EV_COMPONENTADDED, ComponentChangedEventArgs( e, c ), @this )
  end if
  
  return( cast( ubyte ptr, strptr( _components( c ).value ) ) + e * _components( c ).size )
end function

function Components.addComponent( e as Entity, c as string ) as any ptr
  return( addComponent( e, getID( c ) ) )
end function

function Components.removeComponent( e as Entity, c as ComponentID ) as boolean
  if( _componentMap( e, c ) = true ) then
    _componentMap( e, c ) = false
    
    for i as integer = 0 to _componentCount( e ) - 1
      if( _componentTable( e, i ) = c ) then
        _componentTable( e, i ) = _componentTable( e, _componentCount( e ) - 1 )
        _componentCount( e ) -= 1
        exit for
      end if
    next
    
    ECS.raiseEvent( EV_COMPONENTREMOVED, ComponentChangedEventArgs( e, c ), @this )
    
    return( true )
  end if
  
  return( false )
end function

function Components.removeComponent( e as Entity, c as string ) as boolean
  return( removeComponent( e, cast( ComponentTableEntry ptr, _hashTable->find( c ) )->id ) )
end function

function Components.hasComponent( e as Entity, c as ComponentID ) as boolean
  return( _componentMap( e, c ) )
end function

function Components.hasComponent( e as Entity, c as string ) as boolean
  return( hasComponent( e, getID( c ) ) )
end function

sub Components.components_entityDestroyed( _
  sender as any ptr, e as EntityChangedEventArgs, receiver as Components ptr )
  
  if( sender = receiver->_entities ) then
    for i as integer = 0 to receiver->_componentCount( e.eID )
      receiver->_componentMap( e.eID, receiver->_componentTable( e.eID, i ) ) = false
    next
    
    receiver->_componentCount( e.eID ) = 0
  end if
end sub

'' Convenience macro to register components
#macro registerComponent( _cmp_, _n_, _c_ )
  _cmp_.register( _n_, sizeof( _c_ ) )
#endmacro

#endif
