#ifndef __FB_ECS_SYSTEM__
#define __FB_ECS_SYSTEM__

#include once "unordered-list.bi"

type System extends Object
  public:
    declare virtual destructor()
    
    declare property processed() byref as UnorderedList
    
    declare function getDebugInfo() as string
    
    declare virtual sub process( as double = 0.0d )
    
  protected:
    declare constructor()
    declare constructor( as Entities, as Components )
    
    declare property myEntities() byref as Entities
    declare property myComponents() byref as Components
    
    declare function requires( as string ) as any ptr
    declare function has( as string ) as any ptr
    declare function contains( as Entity, as string ) as boolean
    
  private:
    declare static sub event_entityDestroyed( _
      as any ptr, as EntityChangedEventArgs, as System ptr )
    declare static sub event_componentAdded( _
      as any ptr, as ComponentChangedEventArgs, as System ptr )
    declare static sub event_componentRemoved( _
      as any ptr, as ComponentChangedEventArgs, as System ptr )
    
    declare function isRequired( as ComponentID ) as boolean
    declare function hasRequiredComponents( as Entity ) as boolean
    declare function hasOptionalComponent( as Entity ) as boolean
    
    as ComponentID _required( any )
    as ComponentID _has( any )
    as boolean _isProcessed( any )
    
    as UnorderedList _processed
    as Entities ptr _entities
    as Components ptr _components
    as long _requiredCount
    as long _hasCount
end type

constructor System() : end constructor

constructor System( e as Entities, c as Components )
  ECS.registerListener( EV_ENTITYDESTROYED, toHandler( System.event_entityDestroyed ), @this )
  ECS.registerListener( EV_COMPONENTADDED, toHandler( System.event_componentAdded ), @this )
  ECS.registerListener( EV_COMPONENTREMOVED, toHandler( System.event_componentRemoved ), @this )
  
  redim _required( 0 to ECS_MAX_COMPONENTS_PER_ENTITY - 1 )
  redim _has( 0 to ECS_MAX_COMPONENTS_PER_ENTITY - 1 )
  redim _isProcessed( 0 to ECS_MAX_ENTITIES - 1 )
  
  _entities = @e
  _components = @c
  _processed = UnorderedList( ECS_MAX_ENTITIES )
end constructor

destructor System()
  ECS.unregisterListener( EV_ENTITYDESTROYED, toHandler( System.event_entityDestroyed ), @this )
  ECS.unregisterListener( EV_COMPONENTADDED, toHandler( System.event_componentAdded ), @this )
  ECS.unregisterListener( EV_COMPONENTREMOVED, toHandler( System.event_componentRemoved ), @this )
  
  erase( _required )
  erase( _has )
  erase( _isProcessed )
end destructor

function System.getDebugInfo() as string
  dim as string s = "["
  
  for i as integer = 0 to _processed.count - 1
    s &= _processed[ i ] & iif( i = _processed.count - 1, "", ";" )
  next
  
  s &= "]" & chr( 13, 10 )
  
  return( s )
end function

property System.processed() byref as UnorderedList
  return( _processed )
end property

property System.myEntities() byref as Entities
  return( *_entities )
end property

property System.myComponents() byref as Components
  return( *_components )
end property

function System.requires( c as string ) as any ptr
  dim as ComponentID id = _components->getID( c )
  
  _required( _requiredCount ) = id
  _requiredCount += 1
  
  return( ( *_components )[ id ] )
end function

function System.has( c as string ) as any ptr
  dim as ComponentID id = _components->getID( c )
  
  _has( _hasCount ) = id
  _hasCount += 1
  
  return( ( *_components )[ id ] )
end function

function System.contains( e as Entity, c as string ) as boolean
  return( _components->hasComponent( e, _components->getID( c ) ) )
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

function System.hasOptionalComponent( e as Entity ) as boolean
  dim as long count
  
  for i as integer = 0 to _hasCount - 1
    if( _components->hasComponent( e, _has( i ) ) ) then count += 1
  next
  
  return( cbool( count > 0 ) andAlso _hasCount > 0 )
end function

sub System.event_entityDestroyed( _
  sender as any ptr, e as EntityChangedEventArgs, receiver as System ptr )
  
  if( sender = receiver->_entities ) then
    var index = receiver->_processed.find( e.eID )
    
    if( index <> -1 ) then
      receiver->_processed.remove( index )
      receiver->_isProcessed( e.eID ) = false
    end if
  end if
end sub

sub System.event_componentAdded( _
  sender as any ptr, e as ComponentChangedEventArgs, receiver as System ptr )
  
  if( sender = receiver->_components ) then
    if( not receiver->_isProcessed( e.eID ) andAlso receiver->hasRequiredComponents( e.eID ) ) then
      if( receiver->_hasCount = 0 orElse receiver->hasOptionalComponent( e.eID ) ) then
        receiver->_isProcessed( e.eID ) = true
        receiver->_processed.add( e.eID )
      end if
    end if
  end if
end sub

sub System.event_componentRemoved( _
  sender as any ptr, e as ComponentChangedEventArgs, receiver as System ptr )
  
  if( sender = receiver->_components ) then
    if( receiver->_isProcessed( e.eID ) andAlso receiver->isRequired( e.cID ) ) then
      receiver->_isProcessed( e.eID ) = false
      receiver->_processed.remove( receiver->_processed.find( e.eID ) )
    end if
  end if
end sub

sub System.process( dt as double = 0.0d ) : end sub

#endif