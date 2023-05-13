#ifndef __FBGAME_MAT3__
#define __FBGAME_MAT3__

namespace __FBG_NS__
  /'
                    | a b c |
    3x3 Matrix type | d e f |
                    | g h i |
    
    Note that this type also defines operators to work with
    2D homogeneous vectors.
    
    08/28/2017
      Fixed typo in multiplication of two matrices
  '/	
  type Mat3
    declare constructor()
    declare constructor(_
      as single, as single, as single, _
      as single, as single, as single, _
      as single, as single, as single )
    declare constructor( as Mat3 )
    declare destructor()
    
    declare operator let( as Mat3 )
    declare operator cast() as string
    
    'declare static function fromEuler( _
    '  as single, as single, as single ) as Mat3
    'declare static function fromEuler( byref as Vec3 ) as Mat3
    declare static function identity() as Mat3
    declare static function empty() as Mat3 
    declare static function translation( as single, as single ) as Mat3
    declare static function translation( as Vec2 ) as Mat3
    declare static function translation( as single, as single, as single ) as Mat3
    declare static function scaling( as single ) as Mat3
    declare static function scaling( as Vec2 ) as Mat3
    declare static function scaling( as Vec2, as Vec2 ) as Mat3
    declare static function rotation( as single ) as Mat3
    declare static function rotation( as single, as Vec2 ) as Mat3
    
    declare function determinant() as single
    declare function transpose() byref as Mat3
    declare function transposed() as Mat3
    declare function inverse() byref as Mat3
    declare function inversed() as Mat3
    declare function toIdentity() byref as Mat3
    declare function toEmpty() byref as Mat3
    
    as single _
      a, b, c, _
      d, e, f, _
      g, h, i
  end type
  
  /'
    The default constructor creates an identity matrix,
    instead of an empty matrix. This is usually far
    more useful.
  '/
  constructor Mat3() 
    a = 1.0: b = 0.0: c = 0.0
    d = 0.0: e = 1.0: f = 0.0
    g = 0.0: h = 0.0: i = 1.0
  end constructor
  
  constructor Mat3( _
    na as single,  nb as single,  nc as single, _
    nd as single,  ne as single,  nf as single, _
    ng as single,  nh as single,  ni as single )
     
    a = na: b = nb: c = nc
    d = nd: e = ne: f = nf
    g = ng: h = nh: i = ni
  end constructor
  
  constructor Mat3( rhs as Mat3 ) 
    a = rhs.a: b = rhs.b: c = rhs.c
    d = rhs.d: e = rhs.e: f = rhs.f
    g = rhs.g: h = rhs.h: i = rhs.i	
  end constructor
  
  destructor Mat3() : end destructor
  
  operator Mat3.let( rhs as Mat3 ) 
    a = rhs.a: b = rhs.b: c = rhs.c
    d = rhs.d: e = rhs.e: f = rhs.f
    g = rhs.g: h = rhs.h: i = rhs.i
  end operator
  
  '' This is only to obtain a human readable representation of the matrix
  operator Mat3.cast() as string 
    return( _
      "| " & trim( str( a ) ) & " | " & trim( str( b ) ) & " | " & trim( str( c ) ) & " |" & chr( 10 ) & chr( 13 ) & _
      "| " & trim( str( d ) ) & " | " & trim( str( e ) ) & " | " & trim( str( f ) ) & " |" & chr( 10 ) & chr( 13 ) & _
      "| " & trim( str( g ) ) & " | " & trim( str( h ) ) & " | " & trim( str( i ) ) & " |" )
  end operator
  
  'function Mat3.fromEuler( aX as single, aY as single, aZ as single ) as Mat3
  '  '' Pitch
  '  dim as single _
  '    theta = rad( aX ), _
  '    sX = sin( theta ), _
  '    cX = cos( theta )
  '  
  '  '' Yaw
  '  theta = rad( aY )
  '  
  '  dim as single _
  '    sY = sin( theta ), _
  '    cY = cos( theta )
  '  
  '  '' Roll
  '  theta = rad( aZ )
  '  
  '  dim as single _
  '    sZ = sin( theta ), _
  '    cZ = cos( theta )
  '  
  '  return( Mat3( _
  '                    cY * cZ,                -cY * sZ,       sY, _
  '     sX * sY * cZ + cX * sZ, -sX * sY * sZ + cX * cZ, -sX * cY, _
  '    -cX * sY * cZ + sX * sZ,  cX * sY * sZ + sX * cZ,  cX * cY ) )
  'end function
  
  'function Mat3.fromEuler( byref angles as Vec3 ) as Mat3
  '  return( Mat3.fromEuler( angles.x, angles.y, angles.z ) )
  'end function
  
  function Mat3.identity() as Mat3
    return( Mat3( _
      1.0, 0.0, 0.0, _
      0.0, 1.0, 0.0, _
      0.0, 0.0, 1.0 ) )
  end function
  
  function Mat3.empty() as Mat3
    return( Mat3( _
      0.0, 0.0, 0.0, _
      0.0, 0.0, 0.0, _
      0.0, 0.0, 0.0 ) )
  end function
  
  function Mat3.translation( tx as single, ty as single ) as Mat3
    return( Mat3( _
      1.0, 0.0, tx, _
      0.0, 1.0, ty, _
      0.0, 0.0, 1.0 ) )
  end function
  
  function Mat3.translation( t as Vec2 ) as Mat3
    return( Mat3( _
      1.0, 0.0, t.x, _
      0.0, 1.0, t.y, _
      0.0, 0.0, 1.0 ) )
  end function
  
  function Mat3.scaling( s as single ) as Mat3
    return( Mat3( _
        s, 0.0, 0.0, _
      0.0,   s, 0.0, _
      0.0, 0.0,   s ) )
  end function
  
  function Mat3.scaling( s as Vec2 ) as Mat3
    return( Mat3( _
      s.x, 0.0, 0.0, _
      0.0, s.y, 0.0, _
      0.0, 0.0, 1.0 ) )
  end function
  
  function Mat3.scaling( s as Vec2, o as Vec2 ) as Mat3
    return( Mat3( _
      s.x, 0.0, -o.x * s.x + o.x, _
      0.0, s.y, -o.y * s.y + o.y, _
      0.0, 0.0, 1.0 ) )
  end function
  
  function Mat3.rotation( a as single ) as Mat3
    dim as single _
      theta = rad( a ), _
      co = cos( theta ), _
      si = sin( theta )
    
    return( Mat3( _
        co,  -si, 0.0, _
        si,   co, 0.0, _
       0.0,  0.0, 1.0 ) )
  end function
  
  function Mat3.rotation( a as single, o as Vec2 ) as Mat3
    dim as single _
      theta = rad( a ), _
      co = cos( theta ), _
      si = sin( theta )
    
    return( Mat3( _
       co, -si, -o.x * co + o.y * si + o.x, _
       si,  co, -o.x * si - o.y * co + o.y, _
      0.0, 0.0, 1.0 ) )
  end function
  
  '' Computes the determinant of the matrix
  function Mat3.determinant() as single 
    dim as single det = _ 
      ( a * e * i + b * f * g + d * h * c - g * e * c - d * b * i - h * f * a )
    
    /'    
      This is, of course, not matematically correct but it saves
      some comprobations when you're calculating the inverse of
      the matrix (and to avoid a nasty division by zero).
    '/
    return( iif( det = 0.0, 1.0, det ) )
  end function
  
  /'
    Transpose:
  
    | a b c |T    | a d g |
    | d e f |  =  | b e h |
    | g h i |     | c f i |
  '/
  function Mat3.transpose() byref as Mat3
    b += d: d = b - d: b -= d
    c += g: g = c - g: c -= g
    f += h: h = f - h: f -= h
    
    return( this )
  end function
  
  function Mat3.transposed() as Mat3
    return( Mat3( _
      a, d, g, _
      b, e, h, _
      c, f, i ) )
  end function
  
  /'
    Computes the inverse of a 3x3 matrix.
    The inverse is the adjoint divided through the determinant.
  '/
  function Mat3.inverse() byref as Mat3 
    dim as single det = determinant()
    
    '' If the determinant is 0, the matrix has no inverse
    dim as single rDet = 1.0 / det
    
    '' Computes the inverse via Laplace Cofactor Expansion
    this = Mat3( _
      (  e * i - h * f ) * rDet, ( -b * i + h * c ) * rDet, (  b * f - e * c ) * rDet, _
      ( -d * i + g * f ) * rDet, (  a * i - g * c ) * rDet, ( -a * f + d * c ) * rDet, _
      (  d * h - g * e ) * rDet, ( -a * h + g * b ) * rDet, (  a * e - d * b ) * rDet )
    
    return( this )
  end function
  
  function Mat3.inversed() as Mat3
    var M = this
    
    M.inverse()
    
    return( M )
  end function
  
  '' Make the matrix an empty matrix
  function Mat3.toEmpty() byref as Mat3 
    a = 0.0: b = 0.0: c = 0.0
    d = 0.0: e = 0.0: f = 0.0
    g = 0.0: h = 0.0: i = 0.0
    
    return( this )
  end function
  
  '' Make the matrix an identity matrix
  function Mat3.toIdentity() byref as Mat3 
    a = 1.0: b = 0.0: c = 0.0
    d = 0.0: e = 1.0: f = 0.0
    g = 0.0: h = 0.0: i = 1.0
    
    return( this )
  end function
  
  '' Adds two matrices
  operator + ( A as Mat3, B as Mat3 ) as Mat3 
    return( Mat3( _
      A.a + B.a, A.b + B.b, A.c + B.c, _
      A.d + B.d, A.e + B.e, A.f + B.f, _
      A.g + B.g, A.h + B.h, A.i + B.i ) )
  end operator
  
  '' Substracts two matrices
  operator - ( A as Mat3, B as Mat3 ) as Mat3 
    return( Mat3( _
      A.a - B.a, A.b - B.b, A.c - B.c, _
      A.d - B.d, A.e - B.e, A.f - B.f, _
      A.g - B.g, A.h - B.h, A.i - B.i ) )
  end operator
  
  '' Multiply a matrix with a scalar
  operator * ( A as Mat3, s as single ) as Mat3 
    return( Mat3( _
      A.a * s, A.b * s, A.c * s, _
      A.d * s, A.e * s, A.f * s, _
      A.g * s, A.h * s, A.i * s ) )
  end operator
  
  '' Multiply a matrix with a scalar    
  operator * ( s as single, A as Mat3 ) as Mat3 
    return( Mat3( _
      A.a * s, A.b * s, A.c * s, _
      A.d * s, A.e * s, A.f * s, _
      A.g * s, A.h * s, A.i * s ) )
  end operator
  
  '' Multiply two matrices
  operator * ( A as Mat3, B as Mat3 ) as Mat3 
    return( Mat3( _
      A.a * B.a + A.b * B.d + A.c * B.g, A.a * B.b + A.b * B.e + A.c * B.h, A.a * B.c + A.b * B.f + A.c * B.i, _
      A.d * B.a + A.e * B.d + A.f * B.g, A.d * B.b + A.e * B.e + A.f * B.h, A.d * B.c + A.e * B.f + A.f * B.i, _
      A.g * B.a + A.h * B.d + A.i * B.g, A.g * B.b + A.h * B.e + A.i * B.h, A.g * B.c + A.h * B.f + A.i * B.i ) )
  end operator
  
  '' Multiply a matrix with a column vector, resulting in a column vector
  operator * ( A as Mat3, v as Vec2 ) as Vec2 
    return( Vec2( _
      A.a * v.x + A.b * v.y + A.c * v.w, _
      A.d * v.x + A.e * v.y + A.f * v.w, _
      A.g * v.x + A.h * v.y + A.i * v.w ) )  
  end operator
  
  '' Multiply a vector with a row matrix, resulting in a row vector
  operator * ( v as Vec2, A as Mat3 ) as Vec2
    return( Vec2( _
      A.a * v.x + A.d * v.y + A.g * v.w, _
      A.b * v.x + A.e * v.y + A.h * v.w, _
      A.c * v.x + A.f * v.y + A.i * v.w ) )
  end operator
  
  '' Divide a matrix trough a scalar
  operator / ( byref A as Mat3, byref s as single ) as Mat3 
    return( Mat3( _
      A.a / s, A.b / s, A.c / s, _ 
      A.d / s, A.e / s, A.f / s, _
      A.g / s, A.h / s, A.i / s ) )
  end operator
  
  function inverse overload( byval M as Mat3 ) as Mat3
    return( M.inverse() )
  end function
end namespace

#endif