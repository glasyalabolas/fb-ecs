#ifndef __FBGAME_MATH__
#define __FBGAME_MATH__

#include once "fbg-ns.bi"

namespace __FBG_NS__
  const as single _
    Pi = 4.0f * atn( 1.0f ), _
    TwoPi = 2.0f * Pi, _
    degToRad = Pi / 180.0f, _
    radToDeg = 180.0f / Pi
  
  private function rad( a as single ) as single
    return( a * degToRad )
  end function
  
  private function deg( a as single ) as single
    return( a * radToDeg )
  end function
  
  private function max( a as single, b as single ) as single
    return( iif( a > b, a, b ) )
  end function
  
  private function min( a as single, b as single ) as single
    return( iif( a < b, a, b ) )
  end function
  
  private function fMod overload( n as single, d as single ) as single
    return( n - int( n / d ) * d )
  end function
  
  private function wrap overload( x as single, x_min as single, x_max as single ) as single
    return( fMod( fMod( ( x - x_min ), ( x_max - x_min ) ) + ( x_max - x_min ), ( x_max - x_min ) ) + x_min )
  end function
  
  private function clamp( v as single, a as single, b as single ) as single
    return( iif( v < a, a, iif( v > b, b, v ) ) )
  end function
  
  '' Remaps a value from one range into another
  private function remap( _
    x as single, start1 as single, end1 as single, start2 as single, end2 as single ) as single
    
    return( ( x - start1 ) * ( end2 - start2 ) / ( end1 - start1 ) + start2 )
  end function
  
  private function roundUp( x as long, n as long ) as long
    return( int( ( x + n - 1 ) / ( n ) ) * ( ( n * x ) / ( abs( x ) + 0.00001 ) ) )
  end function
end namespace

#include once "fbg-vec2.bi"
#include once "fbg-polar.bi"

#define BT_R( c ) cast( ubyte ptr, @c )[ 2 ]
#define BT_G( c ) cast( ubyte ptr, @c )[ 1 ]
#define BT_B( c ) cast( ubyte ptr, @c )[ 0 ]
#define BT_A( c ) cast( ubyte ptr, @c )[ 3 ]

#macro RGBAlerp( t, c0, c1 )
  rgba( _
    ( ( ( BT_R( c1 ) - BT_R( c0 ) ) * t ) shr 8 ) + BT_R( c0 ), _
    ( ( ( BT_G( c1 ) - BT_G( c0 ) ) * t ) shr 8 ) + BT_G( c0 ), _
    ( ( ( BT_B( c1 ) - BT_B( c0 ) ) * t ) shr 8 ) + BT_B( c0 ), _
    ( ( ( BT_A( c1 ) - BT_A( c0 ) ) * t ) shr 8 ) + BT_A( c0 ) )
#endmacro

#macro RGBlerp( t, c0, c1 )
  rgb( _
    ( ( ( BT_R( c1 ) - BT_R( c0 ) ) * t ) shr 8 ) + BT_R( c0 ), _
    ( ( ( BT_G( c1 ) - BT_G( c0 ) ) * t ) shr 8 ) + BT_G( c0 ), _
    ( ( ( BT_B( c1 ) - BT_B( c0 ) ) * t ) shr 8 ) + BT_B( c0 ) )
#endmacro

namespace __FBG_NS__ 
  private function lerp overload( t as single, p0 as Vec2, p1 as Vec2 ) as Vec2
    return( ( p1 - p0 ) * t + p0 )
  end function
end namespace

#endif
