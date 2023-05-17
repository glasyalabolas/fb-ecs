#ifndef __FBGAME_TEXTURE__
#define __FBGAME_TEXTURE__

#include once "crt.bi"
#include once "fbg-ns.bi"
#include once "fbg-tga.bi"

namespace __FBG_NS__
  type Texture
    public:
      declare constructor()
      declare constructor( as long, as long )
      declare constructor( as Texture )
      declare destructor()
      
      declare operator let( as Texture )
      
      declare static function fromTGA( as const string ) as Texture
      
      declare operator cast() as any ptr
      
      declare property width() as long
      declare property height() as long
      
    private:
      declare constructor( as Fb.Image ptr )
      
      declare sub create( as integer, as integer )
      declare sub dispose()
      
      as Fb.Image ptr _image
      
      #define _pixels( __s__ ) _
        ( cast( ulong ptr, __s__ ) + sizeof( Fb.Image ) \ sizeof( ulong ) )
      #define _pixelCount( __s__ ) _
        ( __s__->height * ( __s__->pitch \ sizeof( ulong ) ) )
  end type
  
  constructor Texture()
    constructor( 1, 1 )
  end constructor
  
  constructor Texture( aWidth as long, aHeight as long )
    create( aWidth, aHeight )
  end constructor
  
  constructor Texture( rhs as Texture )
    create( rhs.width, rhs.height )
    
    memcpy( _
      cast( ubyte ptr, _image ) + sizeof( Fb.Image ), _
      cast( ubyte ptr, rhs ) + sizeof( Fb.Image ), _
      _image->pitch * _image->height )
  end constructor
  
  constructor Texture( anImage as Fb.Image ptr )
    _image = anImage
  end constructor
  
  destructor Texture()
    dispose()
  end destructor
  
  operator Texture.let( rhs as Texture )
    dispose()
    create( rhs.width, rhs.height )
    
    memcpy( _
      cast( ubyte ptr, _image ) + sizeof( Fb.Image ), _
      cast( ubyte ptr, rhs ) + sizeof( Fb.Image ), _
      _image->pitch * _image->height )
  end operator
  
  operator Texture.cast() as any ptr
    return( _image )
  end operator
  
  sub Texture.create( aWidth as integer, aHeight as integer )
    _image = imageCreate( _
      iif( aWidth < 1, 1, aWidth ), _
      iif( aHeight < 1, 1, aHeight ), _
      rgba( 0, 0, 0, 0 ) )
  end sub
  
  sub Texture.dispose()
    imageDestroy( _image )
  end sub
  
  function Texture.fromTGA( aFile as const string ) as Texture
    return( Texture( loadTGA( aFile ) ) )
  end function
  
  property Texture.width() as long
    return( _image->width )
  end property
  
  property Texture.height() as long
    return( _image->height )
  end property
end namespace

#endif
