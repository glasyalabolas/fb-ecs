#ifndef __FB_ECS_SYSTEM__
#define __FB_ECS_SYSTEM__

#include once "unordered-list.bi"

type ECSSystem extends Object
  public:
    declare virtual destructor()
    
    declare property processed() byref as UnorderedList
    
    declare function getDebugInfo() as string
    
    declare virtual sub process( as double = 0.0d )
    
  protected:
    declare constructor()
    declare constructor( as ECSEntities, as ECSComponents )
    
    declare property myEntities() byref as ECSEntities
    declare property myComponents() byref as ECSComponents
    
    declare function requires( as string ) as any ptr
    declare function has( as string ) as any ptr
    declare function contains( as ECSEntity, as string ) as boolean
    
  private:
    declare static sub event_entityDestroyed( _
      as any ptr, as ECSEntityChangedEventArgs, as ECSSystem ptr )
    declare static sub event_componentAdded( _
      as any ptr, as ECSComponentChangedEventArgs, as ECSSystem ptr )
    declare static sub event_componentRemoved( _
      as any ptr, as ECSComponentChangedEventArgs, as ECSSystem ptr )
    
    declare function isRequired( as ECSComponent ) as boolean
    declare function hasRequiredComponents( as ECSEntity ) as boolean
    declare function hasOptionalComponent( as ECSEntity ) as boolean
    
    as ECSComponent _required( any )
    as ECSComponent _has( any )
    as boolean _isProcessed( any )
    
    as UnorderedList _processed
    as ECSEntities ptr _entities
    as ECSComponents ptr _components
    as long _requiredCount
    as long _hasCount
end type

constructor ECSSystem() : end constructor

constructor ECSSystem( e as ECSEntities, c as ECSComponents )
  ECS.registerListener( EV_ENTITYDESTROYED, toHandler( ECSSystem.event_entityDestroyed ), @this )
  ECS.registerListener( EV_COMPONENTADDED, toHandler( ECSSystem.event_componentAdded ), @this )
  ECS.registerListener( EV_COMPONENTREMOVED, toHandler( ECSSystem.event_componentRemoved ), @this )
  
  redim _required( 0 to ECS_MAX_COMPONENTS_PER_ENTITY - 1 )
  redim _has( 0 to ECS_MAX_COMPONENTS_PER_ENTITY - 1 )
  redim _isProcessed( 0 to ECS_MAX_ENTITIES - 1 )
  
  _entities = @e
  _components = @c
  _processed = UnorderedList( ECS_MAX_ENTITIES )
end constructor

destructor ECSSystem()
  ECS.unregisterListener( EV_ENTITYDESTROYED, toHandler( ECSSystem.event_entityDestroyed ), @this )
  ECS.unregisterListener( EV_COMPONENTADDED, toHandler( ECSSystem.event_componentAdded ), @this )
  ECS.unregisterListener( EV_COMPONENTREMOVED, toHandler( ECSSystem.event_componentRemoved ), @this )
  
  erase( _required )
  erase( _has )
  erase( _isProcessed )
end destructor

function ECSSystem.getDebugInfo() as string
  dim as string s = "["
  
  for i as integer = 0 to _processed.count - 1
    s &= _processed[ i ] & iif( i = _processed.count - 1, "", ";" )
  next
  
  s &= "]" & chr( 13, 10 )
  
  return( s )
end function

property ECSSystem.processed() byref as UnorderedList
  return( _processed )
end property

property ECSSystem.myEntities() byref as ECSEntities
  return( *_entities )
end property

property ECSSystem.myComponents() byref as ECSComponents
  return( *_components )
end property

function ECSSystem.requires( c as string ) as any ptr
  dim as ECSComponent id = _components->getID( c )
  
  _required( _requiredCount ) = id
  _requiredCount += 1
  
  return( ( *_components )[ id ] )
end function

function ECSSystem.has( c as string ) as any ptr
  dim as ECSComponent id = _components->getID( c )
  
  _has( _hasCount ) = id
  _hasCount += 1
  
  return( ( *_components )[ id ] )
end function

function ECSSystem.contains( e as ECSEntity, c as string ) as boolean
  return( _components->hasComponent( e, _components->getID( c ) ) )
end function

function ECSSystem.isRequired( c as ECSComponent ) as boolean
  for i as integer = 0 to _requiredCount - 1
    if( _required( i ) = c ) then return( true )
  next
  
  return( false )
end function

function ECSSystem.hasRequiredComponents( e as ECSEntity ) as boolean
  dim as boolean result = true
  
  for i as integer = 0 to _requiredCount - 1
    result = result andAlso _components->hasComponent( e, _required( i ) )
  next
  
  return( result )
end function

function ECSSystem.hasOptionalComponent( e as ECSEntity ) as boolean
  dim as long count
  
  for i as integer = 0 to _hasCount - 1
    if( _components->hasComponent( e, _has( i ) ) ) then count += 1
  next
  
  return( cbool( count > 0 ) andAlso _hasCount > 0 )
end function

sub ECSSystem.event_entityDestroyed( _
  sender as any ptr, e as ECSEntityChangedEventArgs, receiver as ECSSystem ptr )
  
  if( sender = receiver->_entities ) then
    var index = receiver->_processed.find( e.eID )
    
    if( index <> -1 ) then
      receiver->_processed.remove( index )
      receiver->_isProcessed( e.eID ) = false
    end if
  end if
end sub

sub ECSSystem.event_componentAdded( _
  sender as any ptr, e as ECSComponentChangedEventArgs, receiver as ECSSystem ptr )
  
  if( sender = receiver->_components ) then
    if( not receiver->_isProcessed( e.eID ) andAlso receiver->hasRequiredComponents( e.eID ) ) then
      if( receiver->_hasCount = 0 orElse receiver->hasOptionalComponent( e.eID ) ) then
        receiver->_isProcessed( e.eID ) = true
        receiver->_processed.add( e.eID )
      end if
    end if
  end if
end sub

sub ECSSystem.event_componentRemoved( _
  sender as any ptr, e as ECSComponentChangedEventArgs, receiver as ECSSystem ptr )
  
  if( sender = receiver->_components ) then
    if( receiver->_isProcessed( e.eID ) andAlso receiver->isRequired( e.cID ) ) then
      receiver->_isProcessed( e.eID ) = false
      receiver->_processed.remove( receiver->_processed.find( e.eID ) )
    end if
  end if
end sub

sub ECSSystem.process( dt as double = 0.0d ) : end sub

#endif