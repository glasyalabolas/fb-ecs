#ifndef __FB_ECS_ECS__
#define __FB_ECS_ECS__

type ECS extends Object
  public:
    declare static sub registerListener( as Event, as ECSEventHandler, as any ptr = 0 )
    declare static sub unregisterListener( as Event, as ECSEventHandler, as any ptr = 0 )
    declare static sub raiseEvent( as Event, as EventArgs, as any ptr = 0 )
  
  private:
    declare constructor()
    
    static as Events _events
end type

static as Events ECS._events = Events()

sub ECS.registerListener( e as Event, l as ECSEventHandler, r as any ptr = 0 )
  _events.registerListener( e, l, r )
end sub

sub ECS.unregisterListener( e as Event, l as ECSEventHandler, r as any ptr = 0 )
  _events.unregisterListener( e, l, r )
end sub

sub ECS.raiseEvent( ev as Event, e as EventArgs, sender as any ptr = 0 )
  _events.raise( ev, e, sender )
end sub

#endif