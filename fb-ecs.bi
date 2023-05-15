#ifndef __FB_ECS__
#define __FB_ECS__

#include once "inc/ECS-commons.bi"
#include once "inc/ECS-debug.bi"
#include once "inc/ECS-events.bi"
#include once "inc/ECS-ecs.bi"
#include once "inc/ECS-entities.bi"
#include once "inc/ECS-components.bi"
#include once "inc/ECS-system.bi"

/'
  TODO:
    - Save and load states for components and entities
    - Implement serializing to/from XML for easy debugging and data-drive entity
      and component creation
    X Check that systems receive the correct events from the correct components
    X Replace the System.isProcessed() method by a simple lookup into a boolean
      array
    - Double hash the event system: first by event ID, then by sender. This will
      allow to dispatch the events only to systems that are interested in listening
      to a particular event from a specific sender, instead of having all systems
      listen to each event and then discriminate the sender
'/   
#endif
