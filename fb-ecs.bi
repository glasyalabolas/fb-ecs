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
    - Replace the System.isProcessed() method by a simple lookup into a boolean
      array.
'/   
#endif
