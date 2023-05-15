#ifndef __FB_ECS_ECS__
#define __FB_ECS_ECS__

type ECS extends Object
  public:
    declare static sub registerListener( as EventID, as ECSEventHandler, as any ptr = 0 )
    declare static sub unregisterListener( as EventID, as ECSEventHandler, as any ptr = 0 )
    declare static sub raiseEvent( as EventID, as EventArgs, as any ptr = 0 )
  
  private:
    declare constructor()
    
    static as Events _events
end type

static as Events ECS._events = Events()

sub ECS.registerListener( e as EventID, l as ECSEventHandler, r as any ptr = 0 )
  _events.registerListener( e, l, r )
end sub

sub ECS.unregisterListener( e as EventID, l as ECSEventHandler, r as any ptr = 0 )
  _events.unregisterListener( e, l, r )
end sub

sub ECS.raiseEvent( ev as EventID, e as EventArgs, sender as any ptr = 0 )
  _events.raise( ev, e, sender )
end sub

#endif