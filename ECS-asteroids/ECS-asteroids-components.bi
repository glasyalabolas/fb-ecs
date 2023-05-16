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
  as single value
end type

type Score
  as ulong value
end type

type Speed
  as single value
end type

type Lifetime
  as single value
end type

type Ship
  as Entity shipID
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

type Owner
  as Entity id
end type
