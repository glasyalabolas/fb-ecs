#ifndef __ECS_ENTITIES__
#define __ECS_ENTITIES__

#include once "hash-table.bi"

const as long ENTITY_NOT_FOUND = -1
const as long INVALID_ENTITY = -2

type EntityTableEntry
  as string name
  as long idx
end type

type as Components Components_

type Entities extends Object
  public:
    declare constructor()
    declare destructor()
    
    declare function create() as Entity
    declare function create( as string ) as Entity
    declare function find( as string ) as Entity
    declare function destroy( as Entity ) as Entity
    
    declare sub reset()
  
  private:
    declare static sub entities_componentAdded( _
      as any ptr, as ComponentChangedEventArgs, as Entities ptr )
    
    as EntityTableEntry _entities( 0 to ECS_MAX_ENTITIES - 1 )
    as Entity _deleted( 0 to ECS_MAX_ENTITIES - 1 )
    as HashTable _entityMap
    as long _current, _deletedCount
    
    as Components_ ptr _listenTo
end type

constructor Entities()
  _entityMap = HashTable( ECS_MAX_ENTITIES )
  _current = -1
end constructor

destructor Entities()
  erase( _entities )
  erase( _deleted )
end destructor

function Entities.create() as Entity
  if( _deletedCount > 0 ) then
    dim as long tmp = _deleted( _deletedCount - 1 )
    _deletedCount -= 1
    
    ECS.raiseEvent( EV_ENTITYCREATED, EntityChangedEventArgs( tmp ), @this )
    
    return( tmp )
  else
    if( _current < ECS_MAX_ENTITIES ) then
      _current += 1
      
      ECS.raiseEvent( EV_ENTITYCREATED, EntityChangedEventArgs( _current ), @this )
      
      return( _current )
    else
      return( INVALID_ENTITY )
    end if
  end if
end function

function Entities.create( n as string ) as Entity
  return( _entityMap.add( n, create() ) )
end function

function Entities.find( n as string ) as Entity
  return( _entityMap.find( n ) )
end function

function Entities.destroy( e as Entity ) as Entity
  for i as integer = 0 to _deletedCount - 1
    if( _deleted( i ) = e ) then
      return( INVALID_ENTITY )
    end if
  next
  
  _deletedCount += 1
  _deleted( _deletedCount - 1 ) = e
  
  ECS.raiseEvent( EV_ENTITYDESTROYED, EntityChangedEventArgs( e ), @this )
  
  return( e )
end function

sub Entities.reset()
  _current = -1 
  _deletedCount = 0
end sub

#endif
