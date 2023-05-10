#ifndef __ECS_HASH_TABLE__
#define __ECS_HASH_TABLE__

type HashTableEntry
  as string key
  as long value
  as long idx
  as boolean deleted
end type

/'
  Simple but fast hash table implementation that maps strings to indices.
  
  Useful for mapping named entities and components to their indices, to
  avoid having to pass indices around to systems to act on specific
  entities (like the player) or components (such as the map).
  
  It does *NOT* perform automatic rehashings and it will *NOT* automatically
  resize, so if the table is full, no more entries can be added and the table
  needs to be rehashed manually via the provided 'rehash()' method. This is 
  an expensive operation so use with discretion.
  
  Best used for entities that aren't frequently deleted such as the player,
  and specific enemies or components.
'/
type HashTable
  public:
    declare constructor()
    declare constructor( as long )
    declare destructor()
    
    declare function find( as string ) as long
    declare function add( as string, as long ) as long
    declare sub remove( as string )
    declare sub rehash()
    
  private:
    as HashTableEntry ptr _bucket
    as long _index( any ), _size, _count
end type

constructor HashTable()
  constructor( 256 )
end constructor

constructor HashTable( size as long )
  _size = iif( size < 1, 1, size )
  _bucket = new HashTableEntry[ _size ]
  
  redim _index( 0 to _size - 1 )
  
  for i as integer = 0 to _size - 1
    _index( i ) = -1
  next
end constructor

destructor HashTable()
  delete[]( _bucket )
  erase( _index )
end destructor

function HashTable.find( key as string ) as long
  dim as ulong h = hashstr( key ) mod _size
  dim as long current = _index( h )
  
  do while( current <> -1 )
    if( _bucket[ current ].key = key andAlso not _bucket[ current ].deleted ) then
      return( _bucket[ current ].value )
    end if
    
    current = _bucket[ current ].idx
  loop
  
  return( -1 )
end function

function HashTable.add( key as string, value as long ) as long
  if( _count < _size ) then
    dim as ulong h = hashstr( key ) mod _size
    
    _bucket[ _count ].idx = _index( h )
    _bucket[ _count ].key = key
    _bucket[ _count ].value = value
    _index( h ) = _count
    
    _count += 1
    
    return( value )
  end if
  
  return( -1 )
end function

sub HashTable.remove( key as string )
  dim as ulong h = hashstr( key ) mod _size
  dim as long current = _index( h )
  
  do while( current <> -1 )
    if( _bucket[ current ].key = key ) then
      _bucket[ current ].deleted = true
      
      return
    end if
    
    current = _bucket[ current ].idx
  loop
end sub

sub HashTable.rehash()
  var nt = new HashTableEntry[ _size ]
  
  for i as integer = 0 to _size - 1
    _index( i ) = -1
  next
  
  _count = 0
  
  for i as integer = 0 to _size - 1
    if( not _bucket[ i ].deleted andAlso cbool( len( _bucket[ i ].key ) ) ) then
      dim as ulong h = hashstr( _bucket[ i ].key ) mod _size
    
      nt[ _count ].idx = _index( h )
      nt[ _count ].key = _bucket[ i ].key
      nt[ _count ].value = _bucket[ i ].value
      _index( h ) = _count
    
      _count += 1
    end if
  next
  
  delete[]( _bucket )
  _bucket = nt
end sub

#endif