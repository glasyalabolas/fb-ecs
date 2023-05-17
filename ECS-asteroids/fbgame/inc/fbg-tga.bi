#ifndef __FBGAME_TGA__
#define __FBGAME_TGA__

#include once "fbg-ns.bi"
#include once "fbgfx.bi"

namespace __FBG_NS__
  '' TGA file format header
  type TGAHeader field = 1
    as ubyte _
      idLength, _
      colorMapType, _
      dataTypeCode
    as short _
      colorMapOrigin, _
      colorMapLength
    as ubyte _
      colorMapDepth
    as short _
      x_origin, _
      y_origin, _
      width, _
      height
    as ubyte _
      bitsPerPixel, _
      imageDescriptor
  end type
  
  /'
    Loads a TGA image info a Fb.Image buffer.
    
    Currently this loads only 32-bit uncompressed TGA files.		
  '/
  function loadTGA( byref aPath as const string ) as Fb.Image ptr
    dim as long fh = freeFile()
    
    dim as Fb.Image ptr image
    
    dim as long result = open( aPath for binary access read as fh )
    
    if( result = 0 ) then
      dim as TGAHeader h
      
      get #fh, , h
      
      '' Only 32-bit, uncompressed TGA files are supported for now
      if( h.dataTypeCode = 2 andAlso h.bitsPerPixel = 32 ) then
        image = imageCreate( h.width, h.height, rgba( 0, 0, 0, 0 ) )
        
        dim as ulong ptr _
          pix = cptr( ulong ptr, image ) + sizeOf( Fb.Image ) \ sizeOf( ulong )
        
        '' Gets size of padding, as FB aligns its images
        '' to the paragraph (16 bytes) boundary.
        dim as integer padd = image->pitch \ sizeOf( ulong )
        
        dim as ulong ptr buffer = allocate( _
          ( h.width * h.height ) * sizeOf( ulong ) )
        
        get #fh, , *buffer, h.width * h.height
        
        close( fh )
        
        '' Load pixel data onto image
        for y as integer = 0 to h.height - 1
          for x as integer = 0 to h.width - 1
            dim as integer yy = iif( h.y_origin = 0, _
              ( h.height - 1 ) - y, y )
              
            pix[ yy * padd + x ] = buffer[ y * h.width + x ]
          next
        next
        
        deallocate( buffer )
      end if
    else
      ? "Could not found: " & aPath
    end if
    
    return( image )
  end function
end namespace

#endif
