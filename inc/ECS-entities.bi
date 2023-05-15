#ifndef __ECS_ENTITIES__
#define __ECS_ENTITIES__

#include once "fb-hashtable.bi"

const as long INVALID_ENTITY = -1
const as long ENTITY_NOT_FOUND = -2

type EntityTableEntry
  as string name
  as long id
end type

type Entities extends Object
  public:
    declare constructor()
    declare destructor()
    
    declare function create() as Entity
    declare function create( as string ) as Entity
    declare function find( as string ) as Entity
    declare function destroy( as Entity ) as Entity
    
    declare function getInfo() as string
    
    declare sub reset()
  
  private:
    as EntityTableEntry _entities( any )
    as boolean _active( any )
    as FB.HashTable ptr _entityMap
    as long _deletedCount, _last
end type

constructor Entities()
  redim _entities( 0 to ECS_MAX_ENTITIES - 1 )
  redim _active( 0 to ECS_MAX_ENTITIES - 1 )
  
  _entityMap = new Fb.HashTable()
  _last = 0
end constructor

destructor Entities()
  erase( _entities )
  erase( _active )
  
  delete( _entityMap )
end destructor

function Entities.getInfo() as string
  dim as string s
  
  for i as integer = 0 to ECS_MAX_ENTITIES - 1
    s &= iif( i = _last, "<", "[" ) & iif( _active( i ), "1", "0" ) & iif( i = _last, ">", "]" )
  next
  
  return( s )
end function

function Entities.create() as Entity
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

function Entities.create( n as string ) as Entity
  dim as Entity e = create()
  _entityMap->add( n, @_entities( e ) )
  
  return( e )
end function

function Entities.find( n as string ) as Entity
  var entry = cast( EntityTableEntry ptr, _entityMap->find( n ) )
  
  return( iif( entry, entry->id, ENTITY_NOT_FOUND ) )
end function

function Entities.destroy( e as Entity ) as Entity
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

sub Entities.reset()
  '' TODO
end sub

#endif
