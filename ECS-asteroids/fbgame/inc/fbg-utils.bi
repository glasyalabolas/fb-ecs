#ifndef __FBGAME_UTILS__
#define __FBGAME_UTILS__

namespace __FBG_NS__
  private function rng overload( aMin as integer, aMax as integer ) as integer
    return( int( rnd() * ( ( aMax + 1 ) - aMin ) + aMin ) )
  end function
  
  private function rng( aMin as double, aMax as double ) as double
    return( rnd() * ( aMax - aMin ) + aMin )
  end function
  
  private function alignedCenter( x as single, w as single ) as single
    return( ( w - x ) * 0.5f )
  end function
  
  private function alignedRight( x as single, w as single ) as single
    return( w - x )
  end function
  
  sub debugOut( t as const string )
    dim as long fh = freeFile()
    
    open cons for output as fh
      ? #fh, t
    close( fh )
  end sub
end namespace

#endif
