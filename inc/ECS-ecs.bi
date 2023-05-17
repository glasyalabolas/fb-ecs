#ifndef __FB_ECS_ECS__
#define __FB_ECS_ECS__

type ECS extends Object
  public:
    declare static sub registerListener( as ECSEvent, as ECSEventHandler, as any ptr = 0 )
    declare static sub unregisterListener( as ECSEvent, as ECSEventHandler, as any ptr = 0 )
    declare static sub raiseEvent( as ECSEvent, as ECSEventArgs, as any ptr = 0 )
  
  private:
    declare constructor()
    
    static as ECSEvents _events
end type

static as ECSEvents ECS._events = ECSEvents()

sub ECS.registerListener( e as ECSEvent, l as ECSEventHandler, r as any ptr = 0 )
  _events.registerListener( e, l, r )
end sub

sub ECS.unregisterListener( e as ECSEvent, l as ECSEventHandler, r as any ptr = 0 )
  _events.unregisterListener( e, l, r )
end sub

sub ECS.raiseEvent( ev as ECSEvent, e as ECSEventArgs, sender as any ptr = 0 )
  _events.raise( ev, e, sender )
end sub

#endif