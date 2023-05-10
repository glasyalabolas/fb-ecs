#ifndef __TABLE__
#define __TABLE__

#include once "unordered-list.bi"

type Table
  declare constructor()
  declare constructor( as uinteger )
  declare constructor( as uinteger, as uinteger )
  declare destructor()
  
  as UnorderedList _table( any )
end type

constructor Table()
  constructor( 256 )
end constructor

constructor Table( size as uinteger )
  constructor( size, 16 )
end constructor

constructor Table( size as uinteger, bucketSize as uinteger )
  redim _table( 0 to iif( size < 16, 16, size ) )
  
  for i as integer = 0 to ubound( _table )
    _table( i ) = UnorderedList( bucketSize )
  next
end constructor

destructor Table()
  erase( _table )
end destructor

#endif
