#ifndef __FB_HASHTABLE_BI__
#define __FB_HASHTABLE_BI__

#include once "fb-linkedlist.bi"

namespace Fb
  type HashTableEntry
    declare constructor( as string, as any ptr )
    declare destructor()
    
    as string key
    as any ptr value
  end type
  
  private constructor HashTableEntry( k as string, v as any ptr )
    key = k
    value = v
  end constructor
  
  private destructor HashTableEntry() : end destructor
  
  private function getHash( value as string ) as ulong
    #define ROT( a, b ) ( ( a shl b ) or ( a shr ( 32 - b ) ) )
    
    dim as zstring ptr strp = strPtr( value )
    dim as integer _
      l = len( value ), _
      extra_bytes = l and 3
    
    l shr= 2
    
    dim as ulong hash = &hdeadbeef
    
    do while( l )
      hash += *cast( ulong ptr, strp )
      strp += 4
      hash = ( hash shl 5 ) - hash
      hash xor= ROT( hash, 19 )
      l -= 1
    loop
    
    if( extra_bytes ) then
      select case as const( extra_bytes )
        case 3
          hash xor= *cast( ulong ptr, strp ) and &hffffff
        case 2
          hash xor= *cast( ulong ptr, strp ) and &hffff
        case 1
          hash xor= *strp
      end select
      
      hash = ( hash shl 5 ) - hash
      hash xor= rot( hash, 19 )
    end if
    
    hash += ROT( hash, 2 )
    hash xor= ROT( hash, 27 )
    hash += ROT( hash, 16 )
    
    return( hash )
  end function
  
  '' Hash table
  type HashTable
    public:
      declare constructor()
      declare constructor( as integer )
      declare destructor()
      
      declare operator [] ( as string ) as any ptr
      
      declare property size() as integer
      declare property count() as integer
      
      declare function containsKey( as string ) as boolean
      declare sub getKeys( a() as string )
      declare function add( as string, as any ptr ) as any ptr
      declare function remove( as string ) as any ptr
      declare function clear() byref as HashTable
      declare function find( as string ) as any ptr
      
      declare function findEntry( as string ) as HashTableEntry ptr
      declare function findBucket( as string ) as LinkedList ptr
    
    private:
      declare constructor( as HashTable )
      declare operator let( as HashTable )
      
      declare sub _dispose( as integer, as LinkedList ptr ptr ) 
      declare sub _setResizeThresholds( as integer, as single, as single )
      declare sub _addEntry( as HashTableEntry ptr, as LinkedList ptr ptr, as integer )
      declare function _removeEntry( as string ) as HashTableEntry ptr
      declare sub _rehash( as integer )
      
      as LinkedList ptr ptr _hashTable
      
      as integer _
        _count, _
        _size, _
        _initialSize, _
        _maxThreshold, _
        _minThreshold
      
      static as const single _
        LOWER_THRESHOLD, _
        UPPER_THRESHOLD
  end type
  
  dim as const single _
    HashTable.LOWER_THRESHOLD = 0.55f, _
    HashTable.UPPER_THRESHOLD = 0.85f
  
  private constructor HashTable()
    constructor( 256 )
  end constructor
  
  private constructor HashTable( aSize as integer )
    _initialSize = iif( aSize < 32, 32, aSize )
    _size = _initialSize
    
    _hashTable = callocate( _size, sizeof( LinkedList ptr ) )
    
    _setResizeThresholds( _initialSize, LOWER_THRESHOLD, UPPER_THRESHOLD )
  end constructor
  
  private constructor HashTable( rhs as HashTable ) : end constructor
  private operator HashTable.let( rhs as HashTable ) : end operator
  
  private destructor HashTable()
    _dispose( _size, _hashTable )
    
    deallocate( _hashTable )
  end destructor
  
  private operator HashTable.[] ( k as string ) as any ptr
    var e = findEntry( k )
    return( iif( e <> 0, e->value, 0 ) )
  end operator
  
  private property HashTable.count() as integer
    return( _count )
  end property
  
  private property HashTable.size() as integer
    return( _size )
  end property
  
  private sub HashTable._dispose( s as integer, ht as LinkedList ptr ptr )
    for i as integer = 0 to s - 1
      if( ht[ i ] <> 0 ) then
        do while( ht[ i ]->count > 0 )
          delete( cast( HashTableEntry ptr, ht[ i ]->removeLast() ) )
        loop
        
        delete( ht[ i ] )
        ht[ i ] = 0
      end if
    next
  end sub
  
  private sub HashTable._setResizeThresholds( _
    newSize as integer, lower as single, upper as single )
    
    newSize = iif( newSize < _initialSize, _
	    _initialSize, newSize )
    
    dim as integer previous = newSize shr 1
    
    previous = iif( previous < _initialSize, 0, previous )
    
    _minThreshold = int( previous * lower )
    _maxThreshold = int( newSize * upper )
  end sub
  
  private sub HashTable._rehash( newSize as integer )
    _setResizeThresholds( newSize, LOWER_THRESHOLD, UPPER_THRESHOLD )
    
    dim as LinkedList ptr ptr _
      newTable = callocate( newSize, sizeof( LinkedList ptr ) )
    
    _count = 0
    
    for i as integer = 0 to _size - 1
      var bucket = _hashTable[ i ]
      
      if( bucket <> 0 ) then
        var n = bucket->first
        
        do while( n <> 0 )
          _addEntry( n->item, newTable, newSize )
          
          n->item = 0
          n = n->forward
        loop
      end if
    next
    
    _dispose( _size, _hashTable )
    deallocate( _hashTable )
    
    _size = newSize
    _hashTable = newTable
  end sub
  
  private function HashTable.findBucket( k as string ) as LinkedList ptr
    return( _hashTable[ getHash( k ) mod _size ] )
  end function
  
  private function HashTable.findEntry( k as string ) as HashTableEntry ptr
    dim as HashTableEntry ptr e = 0
    
    var bucket = findBucket( k )
    
    if( bucket <> 0 ) then
      var n = bucket->last
      
      do while( n <> 0 )
        if( cast( HashTableEntry ptr, n->item )->key = k ) then
          e = n->item
          exit do
        end if
        
        n = n->backward
      loop
    end if
    
    return( e )
  end function
  
  private function HashTable.clear() byref as HashTable
    _dispose( _size, _hashTable )
    
    _size = _initialSize
    _count = 0
    
    _setResizeThresholds( _initialSize, LOWER_THRESHOLD, UPPER_THRESHOLD )
    
    return( this )
  end function
  
  private function HashTable.containsKey( k as string ) as boolean
    return( cbool( findEntry( k ) <> 0 ) )
  end function
  
  private sub HashTable.getKeys( a() as string )
    redim a( 0 to _count - 1 )
    
    dim as integer item
    
    for i as integer = 0 to _size - 1
      if( _hashTable[ i ] <> 0 ) then
        var n = _hashTable[ i ]->last
        
        for j as integer = 0 to _hashTable[ i ]->count - 1
          a( item ) = cast( HashTableEntry ptr, n->item )->key
          item += 1
          
          n = n->backward
        next
      end if
    next
  end sub
  
  private function HashTable.find( k as string ) as any ptr
    var e = findEntry( k )
    return( iif( e <> 0, e->value, 0 ) )
  end function
  
  private sub HashTable._addEntry( _
    e as HashTableEntry ptr, ht as LinkedList ptr ptr, s as integer )
    
    dim as ulong bucket = getHash( e->key ) mod s
    
    if( ht[ bucket ] = 0 ) then
      ht[ bucket ] = new LinkedList()
      ht[ bucket ]->addLast( e )
    else
      ht[ bucket ]->addLast( e )
    end if
    
    _count += 1
  end sub
  
  private function HashTable.add( k as string, v as any ptr ) as any ptr
    _addEntry( new HashTableEntry( k, v ), _hashTable, _size )
    
    if( _count > _maxThreshold ) then
      _rehash( _size shl 1 )
    end if
    
    return( v )
  end function
  
  private function HashTable._removeEntry( k as string ) as HashTableEntry ptr
    var bucket = findBucket( k )
    
    dim as HashTableEntry ptr e = 0
    
    if( bucket <> 0 ) then
      var n = bucket->last
      
      do while( n <> 0 )
        if( cast( HashTableEntry ptr, n->item )->key = k ) then
          e = bucket->remove( n )
          
          _count -= 1
          
          if( _count < _minThreshold ) then
            _rehash( _size shr 1 )
          end if
          
          exit do
        end if
        
        n = n->backward
      loop
    end if
    
    return( e )
  end function
  
  private function HashTable.remove( k as string ) as any ptr
    var bucket = findBucket( k )
    
    dim as any ptr item
    
    if( bucket <> 0 ) then
      var n = bucket->last
      
      do while( n <> 0 )
        if( cast( HashTableEntry ptr, n->item )->key = k ) then
          dim as HashTableEntry ptr e = bucket->remove( n )
          
          item = e->value
          delete( e )
          
          _count -= 1
          
          if( _count < _minThreshold ) then
            _rehash( _size shr 1 )
          end if
          
          exit do
        end if
        
        n = n->backward
      loop
    end if
    
    return( item )
  end function
end namespace

#endif
