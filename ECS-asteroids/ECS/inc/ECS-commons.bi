#ifndef __ECS_COMMONS__
#define __ECS_COMMONS__

const as long ECS_MAX_ENTITIES = 1000
const as long ECS_MAX_COMPONENTS = 50
const as long ECS_MAX_COMPONENTS_PER_ENTITY = 32

type as long Entity
type as long ECS_EVENT

function hash_32( x as ulong ) as ulong
  x = ( ( x shr 16 ) xor x ) * &h45d9f3b
  x = ( ( x shr 16 ) xor x ) * &h45d9f3b
  return( ( x shr 16 ) xor x )
end function

function hash_64( x as ulongint ) as ulongint
  x = ( x xor ( x shr 30 ) ) * &hbf58476d1ce4e5b9ull
  x = ( x xor ( x shr 27 ) ) * &h94d049bb133111ebull
  return( ( x shr 31 ) xor x )
end function

function hashstr( x as string ) as ulong
  #define ROT( a, b ) ( ( a shl b ) or ( a shr ( 32 - b ) ) )
  
  dim as zstring ptr strp = strPtr( x )
  dim as integer _
    leng = len( x ), _
    extra_bytes = leng and 3
  
  leng shr= 2
  
  dim as ulong h = &hdeadbeef
  
  do while( leng )
    h += *cast( ulong ptr, strp )
    strp += 4
    h = ( h shl 5 ) - h
    h xor= ROT( h, 19 )
    leng -= 1
  loop
  
  if( extra_bytes ) then
    select case as const( extra_bytes )
      case 3
        h xor= *cast( ulong ptr, strp ) and &hffffff
      case 2
        h xor= *cast( ulong ptr, strp ) and &hffff
      case 1
        h xor= *strp
    end select
    
    h = ( h shl 5 ) - h
    h xor= rot( h, 19 )
  end if
  
  h += ROT( h, 2 )
  h xor= ROT( h, 27 )
  h += ROT( h, 16 )
  
  return( h )
end function

#endif