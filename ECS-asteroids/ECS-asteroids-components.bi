type Movable
  as Vec2 pos
end type

type Orientable
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

type Controllable
  as long _
    forward, backward, _
    rotateLeft, rotateRight, _
    fire, strafe
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

type Collidable
  as BoundingCircle shape
end type

type Ship
  as Entity shipID
end type

type ControlParameters
  as single rateOfFire, accel, turnSpeed
end type
