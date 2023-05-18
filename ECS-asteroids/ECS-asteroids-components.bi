#ifndef __ECS_ASTEROIDS_COMPONENTS_
#define __ECS_ASTEROIDS_COMPONENTS_

type Position
  as Vec2 pos
end type

type Orientation
  as Vec2 dir
end type

type Physics
  as Vec2 vel
  as single maxSpeed
end type

type Appearance
  as color_t color
end type

type Dimensions
  as single size
end type

type Health
  as single current, max
end type

type Score
  as ulong value
end type

type ScoreValue
  as long value
end type

type Speed
  as single value
end type

type Lifetime
  as single current, max
end type

type Ship
  as ECSEntity shipID
end type

type Controls
  as long _
    forward, backward, _
    rotateLeft, rotateRight, _
    fire, strafe
end type

type ControlParameters
  as single rateOfFire, accel, turnSpeed
end type

type Collision
  as single radius
end type

type Parent
  as ECSEntity id
end type

#endif
