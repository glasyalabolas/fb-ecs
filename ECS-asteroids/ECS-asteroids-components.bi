#ifndef __ECS_ASTEROIDS_COMPONENTS_
#define __ECS_ASTEROIDS_COMPONENTS_

/'
  Components are just POD structures. There's no restrictions as to whether they need
  to be or not, so you might have components with methods if you find a use for them.
'/
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

type Damaged
  as boolean value
end type

type AsteroidRenderData
  as Vec2 points( any )
  as long faces
end type

#endif
