#ifndef __UNORDERED_LIST__
#define __UNORDERED_LIST__

type UnorderedList
  declare constructor()
  declare constructor( as ulong )
  declare destructor()
  
  declare operator []( as integer ) as long
  
  declare property count() as integer
   
  declare function find( as long ) as long
  declare function add( as long ) as long
  declare sub remove( as long )
  
  declare sub clear()
  
  private:
    as long _list( any )
    as integer _count
end type

constructor UnorderedList()
  constructor( 256 )
end constructor

constructor UnorderedList( size as ulong )
  redim _list( 0 to iif( size < 16, 16, size ) - 1 )
end constructor

destructor UnorderedList()
  erase( _list )
end destructor

operator UnorderedList.[]( index as integer ) as long
  return( _list( index ) )
end operator

property UnorderedList.count() as integer
  return( _count )
end property

function UnorderedList.find( item as long ) as long
  for i as integer = 0 to _count - 1
    if( _list( i ) = item ) then return( i )
  next
  
  return( -1 )
end function

function UnorderedList.add( item as long ) as long
  _list( _count ) = item
  _count += 1
  
  return( _count - 1 )
end function

sub UnorderedList.remove( index as long )
  _list( index ) = _list( _count - 1 )
  _count -= 1
end sub

sub UnorderedList.clear()
  _count = 0
end sub

#endif
