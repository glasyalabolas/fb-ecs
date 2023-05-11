#ifndef __ECS_ENTITIES__
#define __ECS_ENTITIES__

#include once "hash-table.bi"

type EntityTableEntry
  as string name
  as long idx
end type

type EntityChangedEventArgs extends EventArgs
  declare constructor( as Entity )
  
  as Entity eID
end type

constructor EntityChangedEventArgs( e as Entity )
  eID = e
end constructor

type Entities extends Object
  public:
    declare constructor()
    declare destructor()
    declare function create() as Entity
    declare function create( as string ) as Entity
    declare function find( as string ) as Entity
    declare function destroy( as Entity ) as long
    
    declare sub reset()
  
  private:
    as EntityTableEntry _entities( 0 to ECS_MAX_ENTITIES - 1 )
    as Entity _deleted( 0 to ECS_MAX_ENTITIES - 1 )
    as HashTable _entityMap
    as long _current, _deletedCount
end type

constructor Entities()
  _entityMap = HashTable( ECS_MAX_ENTITIES )
end constructor

destructor Entities()
  erase( _entities )
  erase( _deleted )
end destructor

function Entities.create() as Entity
  if( _deletedCount > 0 ) then
    dim as long tmp = _deleted( _deletedCount - 1 )
    _deletedCount -= 1
    
    ECS.raiseEvent( EV_ENTITYCREATED, EntityChangedEventArgs( tmp ) )
    
    return( tmp )
  else
    if( _current < ECS_MAX_ENTITIES ) then
      _current += 1
      
      ECS.raiseEvent( EV_ENTITYCREATED, EntityChangedEventArgs( _current ) )
      
      return( _current )
    else
      return( -1 )
    end if
  end if
end function

function Entities.create( n as string ) as Entity
  return( _entityMap.add( n, create() ) )
end function

function Entities.find( n as string ) as Entity
  return( _entityMap.find( n ) )
end function

function Entities.destroy( e as Entity ) as long
  for i as integer = 0 to _deletedCount - 1
    if( _deleted( i ) = e ) then
      return( -1 )
    end if
  next
  
  _deletedCount += 1
  _deleted( _deletedCount - 1 ) = e
  
  ECS.raiseEvent( EV_ENTITYDESTROYED, EntityChangedEventArgs( e ) )
  
  return( e )
end function

sub Entities.reset()
  _current = -1
  _deletedCount = 0
end sub

#endif