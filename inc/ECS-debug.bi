#ifndef __ECS_DEBUG__
#define __ECS_DEBUG__

type Debug extends Object
  declare static sub toFile( as string )
  declare static sub toConsole()
  declare static sub print( as string )
  
  private:
    declare constructor()
    
    static as string _file
    static as long _handle
    static as boolean _opened
end type

static as string Debug._file
static as long Debug._handle = 0
static as boolean Debug._opened

sub Debug.toFile( n as string )
  if( n <> _file ) then
    if( _handle <> 0 ) then
      close( _handle )
      _opened = false
    end if
    
    _handle = freeFile()
    _file = n
    
    open _file for append as _handle
    _opened = true
  end if
end sub

sub Debug.toConsole()
  if( _handle ) then
    close( _handle )
    _handle = 0
    _opened = false
    _file = ""
  end if
  
  if( not _opened ) then
    _handle = freeFile()
    
    open cons for output as _handle
    _opened = true
  end if 
end sub

sub Debug.print( s as string )
  ? #_handle, s
end sub

#endif
