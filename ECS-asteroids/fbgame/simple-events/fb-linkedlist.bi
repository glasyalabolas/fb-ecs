#ifndef __FB_LINKEDLIST_BI__
#define __FB_LINKEDLIST_BI__

namespace Fb
  #ifndef FBNULL
    #define FBNULL cast( any ptr, 0 )
  #endif
  
  type LinkedListNode
    declare constructor()
    declare constructor( as any ptr )
    
    as LinkedListNode ptr forward, backward
    as any ptr item
  end type
  
  private constructor LinkedListNode() : end constructor
  
  private constructor LinkedListNode( anItem as any ptr )
    item = anItem
  end constructor
  
  '' (Doubly) Linked List
  type LinkedList
    public:
      declare constructor()
      declare destructor()
      
      declare operator [] ( as integer ) as any ptr
      
      declare property count() as integer
      declare property first() as LinkedListNode ptr
      declare property last() as LinkedListNode ptr
      
      declare sub clear()
      declare function addBefore( as LinkedListNode ptr, as any ptr ) as LinkedListNode ptr
      declare function addAfter( as LinkedListNode ptr, as any ptr ) as LinkedListNode ptr
      declare function addFirst( as any ptr ) as LinkedListNode ptr
      declare function addLast( as any ptr ) as LinkedListNode ptr
      declare function remove( as LinkedListNode ptr ) as any ptr
      declare function removeFirst() as any ptr
      declare function removeLast() as any ptr
    
    private:
      declare sub _dispose()
      
      as LinkedListNode ptr _first, _last
      as integer _count
  end type
  
  private constructor LinkedList() : end constructor
  
  private destructor LinkedList()
    clear()
  end destructor
  
  private operator LinkedList.[]( index as integer ) as any ptr
    var n = _first
    
    for i as integer = 0 to _count - 1
      if( i = index ) then
        return( n->item )
      end if
      
      n = n->forward
    next
    
    return( FBNULL )
  end operator
  
  private property LinkedList.count() as integer
    return( _count )
  end property
  
  private property LinkedList.first() as LinkedListNode ptr
    return( _first )
  end property
  
  private property LinkedList.last() as LinkedListNode ptr
    return( _last )
  end property
  
  private sub LinkedList.clear()
    do while( _count > 0 )
      remove( _last )
    loop
    
    _first = FBNULL
    _last = _first
  end sub
  
  private function LinkedList.addBefore( _
    node as LinkedListNode ptr, item as any ptr ) as LinkedListNode ptr
    
    var newNode = new LinkedListNode( item )
    
    newNode->backward = node->backward
    newNode->forward = node
    
    if( node->backward = FBNULL ) then
      _first = newNode
    else
      node->backward->forward = newNode
    end if
    
    _count += 1
    node->backward = newNode
    
    return( newNode )
  end function
  
  private function LinkedList.addAfter( _
    node as LinkedListNode ptr, item as any ptr ) as LinkedListNode ptr
    
    var newNode = new LinkedListNode( item )
    
    newNode->backward = node
    newNode->forward = node->forward
    
    if( node->forward = FBNULL ) then
      _last = newNode
    else
      node->forward->backward = newNode
    end if
    
    _count += 1
    node->forward = newNode
    
    return( newNode )
  end function
  
  private function LinkedList.addFirst( item as any ptr ) as LinkedListNode ptr
    if( _first = FBNULL ) then
      var newNode = new LinkedListNode( item )
      
      _first = newNode
      _last = newNode
      
      newNode->backward = FBNULL
      newNode->forward = FBNULL
      
      _count += 1
      
      return( newNode )
    end if
    
    return( addBefore( _first, item ) )
  end function
  
  private function LinkedList.addLast( item as any ptr ) as LinkedListNode ptr
    return( iif( _last = FBNULL, addFirst( item ), addAfter( _last, item ) ) )
  end function
  
  private function LinkedList.remove( node as LinkedListNode ptr ) as any ptr
    dim as any ptr item = FBNULL
    
    if( node <> 0 andAlso _count > 0 ) then
      if( node->backward = FBNULL ) then
        _first = node->forward
      else
        node->backward->forward = node->forward
      end if
      
      if( node->forward = FBNULL ) then
        _last = node->backward
      else
        node->forward->backward = node->backward
      end if
      
      _count -= 1
      item = node->item
      
      delete( node )
    end if
    
    return( item )
  end function
  
  private function LinkedList.removeFirst() as any ptr
    return( remove( _first ) )
  end function
  
  private function LinkedList.removeLast() as any ptr
    return( remove( _last ) )
  end function
end namespace

#endif
