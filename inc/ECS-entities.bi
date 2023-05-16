#ifndef __FB_ECS_ENTITIES__
#define __FB_ECS_ENTITIES__

#include once "fb-hashtable.bi"

const as long INVALID_ENTITY = -1
const as long ENTITY_NOT_FOUND = -2

type ECSEntityTableEntry
  as string name
  as long id
end type

type ECSEntities extends Object
  public:
    declare constructor()
    declare destructor()
    
    declare function create() as Entity
    declare function create( as string ) as Entity
    declare function find( as string ) as Entity
    declare function getName( as Entity ) as string
    declare function destroy( as Entity ) as Entity
    
    declare function getInfo() as string
    
    declare sub reset()
  
  private:
    as ECSEntityTableEntry _entities( any )
    as boolean _active( any )
    as FB.HashTable ptr _entityMap
    as long _deletedCount, _last
end type

constructor ECSEntities()
  redim _entities( 0 to ECS_MAX_ENTITIES - 1 )
  redim _active( 0 to ECS_MAX_ENTITIES - 1 )
  
  _entityMap = new Fb.HashTable()
  _last = 0
end constructor

destructor ECSEntities()
  erase( _entities )
  erase( _active )
  
  delete( _entityMap )
end destructor

function ECSEntities.getInfo() as string
  dim as string s
  
  for i as integer = 0 to ECS_MAX_ENTITIES - 1
    s &= iif( i = _last, "<", "[" ) & iif( _active( i ), "1", "0" ) & iif( i = _last, ">", "]" )
  next
  
  return( s )
end function

function ECSEntities.create() as Entity
  dim as long current = _last
  dim as long count
  
  do while( _active( current ) andAlso count < ECS_MAX_ENTITIES )
    current = ( current + 1 ) mod ECS_MAX_ENTITIES
    count += 1
  loop
  
  if( count < ECS_MAX_ENTITIES ) then
    _last = current
    _active( current ) = true
    _entities( current ).id = current
    
    ECS.raiseEvent( EV_ENTITYCREATED, EntityChangedEventArgs( current ), @this )
    
    return( current )
  else
    return( INVALID_ENTITY )
  end if
end function

function ECSEntities.create( n as string ) as Entity
  dim as Entity e = create()

  _entities( e ).name = n
  _entityMap->add( n, @_entities( e ) )
  
  return( e )
end function

function ECSEntities.find( n as string ) as Entity
  var entry = cast( ECSEntityTableEntry ptr, _entityMap->find( n ) )
  
  return( iif( entry, entry->id, ENTITY_NOT_FOUND ) )
end function

function ECSEntities.getName( e as Entity ) as string
  return( _entities( e ).name )
end function

function ECSEntities.destroy( e as Entity ) as Entity
  if( _active( e ) ) then
    _active( e ) = false
    _last = e
    
    if( len( _entities( e ).name ) ) then
      _entityMap->remove( _entities( e ).name )
    end if
    
    ECS.raiseEvent( EV_ENTITYDESTROYED, EntityChangedEventArgs( e ), @this )
    
    return( e )
  end if

  return( INVALID_ENTITY )
end function

sub ECSEntities.reset()
  '' TODO
end sub

#endif
