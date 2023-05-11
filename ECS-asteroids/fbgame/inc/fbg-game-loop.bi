#ifndef __FBGAME_LOOP__
#define __FBGAME_LOOP__

#include once "fbg-ns.bi"

namespace __FBG_NS__
  type GameLoop extends Object
    public:
      declare constructor()
      declare constructor( as double, as double )
      declare virtual destructor()
      
      declare property ticksPerSecond() as double
      declare property deltaTime() as double
      
      declare sub start()
      declare sub run()
      
    private:
      declare abstract sub onUpdate( as double )
      declare abstract sub onRender( as double )
      
      declare function getTickCount() as double
      
      as double _
        _nextTick, _
        _deltaTime, _
        _ticksPerSecond, _
        _skipTicks
  end type
  
  constructor GameLoop()
    constructor( 60.0, 0.1 )
  end constructor
  
  constructor GameLoop( tps as double, dT as double )
    _ticksPerSecond = tps
    _deltaTime = dT
    _skipTicks = 1000.0d / _ticksPerSecond
  end constructor
  
  destructor GameLoop() : end destructor
  
  property GameLoop.ticksPerSecond() as double
    return( _ticksPerSecond )
  end property
  
  property GameLoop.deltaTime() as double
    return( _deltaTime )
  end property
  
  function GameLoop.getTickCount() as double
    return( timer() * 1000.0d )
  end function
  
  sub GameLoop.start()
    _nextTick = getTickCount()
  end sub
  
  sub GameLoop.run()
    do while( getTickCount() > _nextTick )
      '' Call the delegate in charge of updating
      onUpdate( _deltaTime )
      
      _nextTick += _skipTicks
    loop
    
    '' Render
    onRender( ( getTickCount() + _skipTicks - _nextTick ) / _skipTicks )
    
    '' Yield a little time to other threads
    sleep( 1, 1 )
  end sub
end namespace

#endif
