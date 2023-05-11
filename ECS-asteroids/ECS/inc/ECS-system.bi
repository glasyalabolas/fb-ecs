#ifndef __ECS_SYSTEM__
#define __ECS_SYSTEM__

#include once "unordered-list.bi"

type System extends Object
  public:
    declare virtual destructor()
    
    declare property processed() byref as UnorderedList
    
    declare abstract sub process( as double = 0.0d )
    
  protected:
    declare constructor()
    declare constructor( as Entities, as Components )
    
    declare property getEntities() byref as Entities
    declare property getComponents() byref as Components
    declare property entityCount() as long
    
    declare function requires( as string ) as any ptr
  
  private:
    declare static sub system_entityDestroyed( _
      as any ptr, as EntityChangedEventArgs, as System ptr )
    declare static sub system_componentAdded( _
      as any ptr, as ComponentChangedEventArgs, as System ptr )
    declare static sub system_componentRemoved( _
      as any ptr, as ComponentChangedEventArgs, as System ptr )
    
    declare function isRequired( as ComponentID ) as boolean
    declare function hasRequiredComponents( as Entity ) as boolean
    declare function isProcessed( as Entity ) as boolean
    
    as ComponentID _required( 0 to ECS_MAX_COMPONENTS_PER_ENTITY - 1 )
    as UnorderedList _processed
    as Entities ptr _entities
    as Components ptr _components
    as long _requiredCount
end type

constructor System() : end constructor

constructor System( e as Entities, c as Components )
  ECS.registerListener( EV_ENTITYDESTROYED, toHandler( System.system_entityDestroyed ), @this )
  ECS.registerListener( EV_COMPONENTADDED, toHandler( System.system_componentAdded ), @this )
  ECS.registerListener( EV_COMPONENTREMOVED, toHandler( System.system_componentRemoved ), @this )
  
  _entities = @e
  _components = @c
  _processed = UnorderedList( ECS_MAX_ENTITIES )
end constructor

destructor System()
  ECS.unregisterListener( EV_ENTITYDESTROYED, toHandler( System.system_entityDestroyed ), @this )
  ECS.unregisterListener( EV_COMPONENTADDED, toHandler( System.system_componentAdded ), @this )
  ECS.unregisterListener( EV_COMPONENTREMOVED, toHandler( System.system_componentRemoved ), @this )
  
  erase( _required )
end destructor

property System.processed() byref as UnorderedList
  return( _processed )
end property

property System.entityCount() as long
  return( _processed.count )
end property

property System.getEntities() byref as Entities
  return( *_entities )
end property

property System.getComponents() byref as Components
  return( *_components )
end property

function System.requires( c as string ) as any ptr
  dim as ComponentID id = _components->find( c )
  
  _required( _requiredCount ) = id
  _requiredCount += 1
  
  return( ( *_components )[ id ] )
end function

function System.isRequired( c as ComponentID ) as boolean
  for i as integer = 0 to _requiredCount - 1
    if( _required( i ) = c ) then return( true )
  next
  
  return( false )
end function

function System.hasRequiredComponents( e as Entity ) as boolean
  dim as boolean result = true
  
  for i as integer = 0 to _requiredCount - 1
    result = result andAlso _components->hasComponent( e, _required( i ) )
  next
  
  return( result )
end function

function System.isProcessed( e as Entity ) as boolean
  for i as integer = 0 to _processed.count - 1
    if( _processed[ i ] = e ) then return( true )
  next
  
  return( false )
end function

sub System.system_entityDestroyed( _
  sender as any ptr, e as EntityChangedEventArgs, receiver as System ptr )
  
  var index = receiver->_processed.find( e.eID )
  
  if( index <> -1 ) then
    receiver->_processed.remove( index )
  end if
end sub

sub System.system_componentAdded( _
  sender as any ptr, e as ComponentChangedEventArgs, receiver as System ptr )
  
  if( receiver->hasRequiredComponents( e.eID ) ) then
    receiver->_processed.add( e.eID )
  end if
end sub

sub System.system_componentRemoved( _
  sender as any ptr, e as ComponentChangedEventArgs, receiver as System ptr )
  
  if( receiver->isProcessed( e.eID ) andAlso receiver->isRequired( e.cID ) ) then
    receiver->_processed.remove( receiver->_processed.find( e.eID ) )
  end if
end sub

#endif