#ifndef __FB_ECS__
#define __FB_ECS__

#include once "inc/ECS-commons.bi"
#include once "inc/ECS-events.bi"
#include once "inc/ECS-ecs.bi"
#include once "inc/ECS-entities.bi"
#include once "inc/ECS-components.bi"
#include once "inc/ECS-system.bi"

/'
  IMPORTANT: the range of usable entities is from 1 to MAX_ENTITIES - 1. This is
    because entities start numbering at 1 when you create them.
  
  TODO:
    - Save and load states for components and entities
    - Implement named entities (for quickly find things like the player without
      needing to pass the handle around
    - Implement serializing to/from XML for easy debugging and data-drive entity
      and component creation
'/   
#endif
