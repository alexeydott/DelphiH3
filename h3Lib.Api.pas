unit h3Lib.Api;

{$MINENUMSIZE 4}

interface

uses
  Winapi.Windows, System.Math,System.Classes, System.SysUtils, System.Generics.Collections, System.SyncObjs;

const
{$IF Defined(WIN32)}
  h3dllDefname = 'h3.dll';
{$ELSEIF Defined(WIN64)}
  h3dll = 'h364.dll';
{$ELSE}
  h3dll = 'h3';
  {$MESSAGE Warn 'h3api - Unsupported platform'}
{$ENDIF}
  H3_NULL = 0;
  H3_VERSION_MAJOR = 4;
  H3_VERSION_MINOR = 1;
  H3_VERSION_PATCH = 0;
  MAX_CELL_BNDRY_VERTS = 10;
  H3_DLL_PATH = 'H3_DLL_PATH';

  {$region '  constants for bitwise manipulation of TH3Index's.'}
  ///<summary>Minimal resolution level of h3</summary>
  H3_RES_MIN = 0;
  ///<summary>Maximum resolution level of h3</summary>
  H3_RES_MAX = 15;
  ///<summary>The number of bits in an H3 index.</summary>
  H3_NUM_BITS = 64;
  ///<summary>The bit offset of the max resolution digit in an H3 index</summary>
  H3_MAX_OFFSET = 63;
  ///<summary>The bit offset of the mode in an H3 index.</summary>
  H3_MODE_OFFSET = 59;
  ///<summary>The bit offset of the base cell in an H3 index.</summary>
  H3_BC_OFFSET = 45;
  ///<summary>The bit offset of the resolution in an H3 index.</summary>
  H3_RES_OFFSET = 52;
  ///<summary>The bit offset of the reserved bits in an H3 index.</summary>
  H3_RESERVED_OFFSET = 56;
  ///<summary>The number of bits in a single H3 resolution digit.</summary>
  H3_PER_DIGIT_OFFSET = 3;
  ///<summary>1 in the highest bit, 0's everywhere else.</summary>
  H3_HIGH_BIT_MASK = UInt64(1) shl H3_MAX_OFFSET;
  ///<summary> 0 in the highest bit, 1's everywhere else.</summary>
  H3_HIGH_BIT_MASK_NEGATIVE = not H3_HIGH_BIT_MASK;
  ///<summary>1's in the 4 mode bits, 0's everywhere else.</summary>
  H3_MODE_MASK = UInt64(H3_RES_MAX) shl H3_MODE_OFFSET;
  ///<summary>0's in the 4 mode bits, 1's everywhere else.</summary>
  H3_MODE_MASK_NEGATIVE = not H3_MODE_MASK;
  ///<summary>1's in the 7 base cell bits, 0's everywhere else.</summary>
  H3_BC_MASK = UInt64(127) shl H3_BC_OFFSET;
  ///<summary>0's in the 7 base cell bits, 1's everywhere else.</summary>
  H3_BC_MASK_NEGATIVE = not H3_BC_MASK;
  ///<summary>1's in the 4 resolution bits, 0's everywhere else.</summary>
  H3_RES_MASK = UInt64(H3_RES_MAX) shl H3_RES_OFFSET;
  ///<summary>0's in the 4 resolution bits, 1's everywhere else.</summary>
  H3_RES_MASK_NEGATIVE = not H3_RES_MASK;
  ///<summary>1's in the 3 bits of res 15 digit bits, 0's everywhere else.</summary>
  H3_DIGIT_MASK = UInt64(7);
  ///<summary>0's in the 7 base cell bits, 1's everywhere else.</summary>
  H3_DIGIT_MASK_NEGATIVE = not H3_DIGIT_MASK;
  ///<summary>1's in the 3 reserved bits, 0's everywhere else.</summary>
  H3_RESERVED_MASK = H3_DIGIT_MASK shl H3_RESERVED_OFFSET;
  ///<summary>0's in the 3 reserved bits, 1's everywhere else.</summary>
  H3_RESERVED_MASK_NEGATIVE = not H3_RESERVED_MASK;
  ///<summary>
  /// H3 index with mode 0, res 0, base cell 0, and 7 for all index digits.
  /// Typically used to initialize the creation of an H3 cell index, which
  /// expects all direction digits to be 7 beyond the cell's resolution.
  ///</summary>
  H3_INIT = UInt64(35184372088831);
  // The number of H3 base cells
  H3_NUM_BASE_CELLS = 122;

  ///H3 cell index modes
  H3_CELL_MODE = 1;
  H3_DIRECTEDEDGE_MODE = 2;
  H3_EDGE_MODE = 3;
  H3_VERTEX_MODE = 4;
  {$endregion}

  {$region 'H3 digit representing ijk+ axes direction.'}
  ///<summary>H3 digit in center.</summary>
  H3_DIRECTION_CENTER_DIGIT = 0;
  ///<summary>H3 digit in k-axes direction.</summary>
  H3_DIRECTION_K_AXES_DIGIT = 1;
  ///<summary>H3 digit in j-axes direction.</summary>
  H3_DIRECTION_J_AXES_DIGIT = 2;
  ///<summary>H3 digit in j = k direction.</summary>
  H3_DIRECTION_JK_AXES_DIGIT = H3_DIRECTION_J_AXES_DIGIT or H3_DIRECTION_K_AXES_DIGIT;
  ///<summary>H3 digit in i-axes direction.</summary>
  H3_DIRECTION_I_AXES_DIGIT = 4;
  ///<summary>H3 digit in i = k direction.</summary>
  H3_DIRECTION_IK_AXES_DIGIT =  H3_DIRECTION_I_AXES_DIGIT or H3_DIRECTION_K_AXES_DIGIT;
  ///<summary>H3 digit in i = j direction.</summary>
  H3_DIRECTION_IJ_AXES_DIGIT = H3_DIRECTION_I_AXES_DIGIT or H3_DIRECTION_J_AXES_DIGIT;
  H3_DIRECTION_MIN = H3_DIRECTION_CENTER_DIGIT;
  H3_DIRECTION_MAX = H3_DIRECTION_IJ_AXES_DIGIT;
  ///<summary>H3 digit in the invalid direction.</summary>
  H3_INVALID_DIGIT = 7;
  ///<summary>Valid digits will be less than this value. Same value as INVALID_DIGIT.</summary>
  H3_NUM_DIGITS = H3_INVALID_DIGIT;
  ///<summary>Child digit which is skipped for pentagons.</summary>
  H3_PENTAGON_SKIPPED_DIGIT = H3_DIRECTION_K_AXES_DIGIT;
  {$endregion}

type
  // Forward declarations
  Ph3LatLng = ^Th3LatLng;
  Ph3CellBoundary = ^Th3CellBoundary;
  Ph3GeoLoop = ^Th3GeoLoop;
  Ph3GeoPolygon = ^Th3GeoPolygon;
  Ph3GeoMultiPolygon = ^Th3GeoMultiPolygon;
  Ph3LinkedLatLng = ^Th3LinkedLatLng;
  Ph3LinkedGeoLoop = ^Th3LinkedGeoLoop;
  Ph3LinkedGeoPolygon = ^Th3LinkedGeoPolygon;
  Ph3CoordIJ = ^Th3CoordIJ;

  /// <summary>Identifier for an object (cell, edge, etc) in the H3 system.</summary>
  /// <remarks>The Th3Index fits within a 64-bit unsigned integer.</remarks>
  Ph3Index = ^Th3Index;
  Th3Index = UInt64;

  Th3IndexHelper = record helper for Th3Index
  private
    function GetResolution: Integer;
    procedure SetResolution(Value: Integer);
    function GetReservedBits: Integer;
    function GetBaseCell: Integer;
    procedure SetBaseCell(Value: Integer);
    function GetDigit(AResolution: Integer): Integer;
    procedure SetDigit(AResolution, AValue: Integer);
    function GetCellMode: Integer;
    procedure SetCellMode(AMode: Integer);
  public
    /// <summary>Base cell of h3.integer digit (0-122).</summary>
    property BaseCell: Integer read GetBaseCell write SetBaseCell;
    /// <summary>digit corresponding to a unit vector or the zero vector of h3 in ijk coordinates. integer (0-7).</summary>
    property Digit[Resolution: Integer]: Integer read GetDigit write SetDigit;
    /// <summary>Gets the integer mode of h3.</summary>
    property CellMode: Integer read GetCellMode write SetCellMode;
    /// <summary>Gets the integer resolution of h3.</summary>
    property Resolution: Integer read GetResolution write SetResolution;
    property ReservedBits: Integer read GetReservedBits;
  end;


  /// <summary>Result code (success or specific error) from an H3 operation</summary>
  Th3Error = UInt32;
  Th3ErrorHelper = record helper for Th3Error
    function Succeed: Boolean;
  end;

  Th3ErrorCodes = (
    /// <summary>Success (no error)</summary>
    E_SUCCESS = 0,
    E_FAILED = 1,
    /// <summary>Argument was outside of acceptable range (when a more
    /// specific error code is not available)</summary>
    E_DOMAIN = 2,
    E_LATLNG_DOMAIN = 3,
    /// <summary>Resolution argument was outside of acceptable range</summary>
    E_RES_DOMAIN = 4,
    /// <summary>`Th3Index` cell argument was not valid</summary>
    E_CELL_INVALID = 5,
    /// <summary>`Th3Index` directed edge argument was not valid</summary>
    E_DIR_EDGE_INVALID = 6,
    E_UNDIR_EDGE_INVALID = 7,
    /// <summary>`Th3Index` vertex argument was not valid</summary>
    E_VERTEX_INVALID = 8,
    /// <summary>Pentagon distortion was encountered which the algorithm
    /// could not handle it</summary>
    E_PENTAGON = 9,
    /// <summary>Duplicate input was encountered in the arguments
    /// and the algorithm could not handle it</summary>
    E_DUPLICATE_INPUT = 10,
    /// <summary>`Th3Index` cell arguments were not neighbors</summary>
    E_NOT_NEIGHBORS = 11,
    E_RES_MISMATCH = 12,
    /// <summary>Necessary memory allocation failed</summary>
    E_MEMORY_ALLOC = 13,
    /// <summary>Bounds of provided memory were not large enough</summary>
    E_MEMORY_BOUNDS = 14,
    /// <summary>Mode or flags argument was not valid.</summary>
    E_OPTION_INVALID = 15);
  Ph3ErrorCodes = ^Th3ErrorCodes;

  /// <summary>represents latitude/longitude in radians</summary>
  Th3LatLng = record
    /// <summary>latitude in radians</summary>
    LatitudeInRadians: Double;
    /// <summary>longitude in radians</summary>
    LongitudeInRadians: Double;
    class function Create(const lat,lng: double): Th3LatLng; static;
    function Latitude: Double;
    function Longitude: Double;
  end;

  /// <summary>Th3CellBoundary</summary>
  /// <remarks>cell boundary in latitude/longitude</remarks>
  Th3CellBoundary = record
    /// <summary>number of vertices</summary>
    NumVerts: Integer;
    /// <summary>vertices in ccw order</summary>
    Verts: array [0..9] of Th3LatLng;
  end;

  /// <summary>Th3GeoLoop</summary>
  /// <remarks>similar to Th3CellBoundary, but requires more alloc work</remarks>
  Th3GeoLoop = record
    NumVerts: Integer;
    Verts: Ph3LatLng;
  end;

  /// <summary>Th3GeoPolygon</summary>
  /// <remarks>Simplified core of GeoJSON Polygon coordinates definition</remarks>
  Th3GeoPolygon = record
    /// <summary>exterior boundary of the polygon</summary>
    GeoLoop: Th3GeoLoop;
    /// <summary>number of elements in the array pointed to by holes</summary>
    NumHoles: Integer;
    /// <summary>interior boundaries (holes) in the polygon</summary>
    Holes: Ph3GeoLoop;
  end;

  /// <summary>Th3GeoMultiPolygon</summary>
  /// <remarks>Simplified core of GeoJSON MultiPolygon coordinates definition</remarks>
  Th3GeoMultiPolygon = record
    numPolygons: Integer;
    polygons: Ph3GeoPolygon;
  end;

  Th3LinkedLatLng = record
    vertex: Th3LatLng;
    next: Ph3LinkedLatLng;
  end;

  Th3LinkedGeoLoop = record
    first: Ph3LinkedLatLng;
    last: Ph3LinkedLatLng;
    next: Ph3LinkedGeoLoop;
  end;

  Th3LinkedGeoPolygon = record
    first: Ph3LinkedGeoLoop;
    last: Ph3LinkedGeoLoop;
    next: Ph3LinkedGeoPolygon;
  end;

  /// <summary>Th3CoordIJ</summary>
  /// <remarks>IJ hexagon coordinates
  /// 
  /// Each axis is spaced 120 degrees apart.</remarks>
  Th3CoordIJ = record
    /// <summary>i component</summary>
    i: Integer;
    /// <summary>j component</summary>
    j: Integer;
  end;


  Ih3API = interface(IUnknown)
    ['{B3786A23-6577-4585-9E9B-BC53787B3A0B}']
    {$region 'INDEXING'}
    /// <summary>
    ///   Encodes a given point on the sphere to the H3 index of the containing cell at the specified resolution.
    /// </summary>
    /// <param name="Lat">
    ///   latitude of point to encode.
    /// </param>
    /// <param name="Lng">
    ///   longitude of point to encode.
    /// </param>
    /// <param name="Resolution">
    ///   The desired H3 (0..15) resolution for the encoding.
    /// </param>
    /// <param name="h">
    ///   The encoded H3Index.
    /// </param>
    /// <returns>
    ///   true on success, another value otherwise.
    /// </returns>
    function LatLngToCell(const Lat,Lng: Double; Resolution: Integer; var h: Th3Index): Boolean;
    /// <summary>
    ///   Determines the spherical coordinates of the center point of an H3 index.
    /// </summary>
    /// <param name="h">
    ///   The H3 index.
    /// </param>
    /// <param name="Lat">
    ///   latitude of the H3 cell center.
    /// </param>
    /// <param name="Lng">
    ///   longitude of the H3 cell center.
    /// </param>
    function CellToLatLng(const h: Th3Index; var Lat,Lng: Double): Boolean;
    /// <summary>
    ///   Determines the cell boundary in spherical coordinates for an H3 index.
    /// </summary>
    /// <param name="h">
    ///   The H3 index.
    /// </param>
    /// <param name="CellBoundary">
    ///   The boundary of the H3 cell in spherical coordinates.
    /// </param>
    function CellToBoundary(const h: Th3Index;  var CellBoundary: TArray<Th3LatLng>): Boolean;
    {$endregion}
    function CompactCells(const Source: TArray<Th3Index>; var Compacted: TArray<Th3Index>): Boolean;
  end;

  h3Error = class(Exception)
  end;

  Th3Api = class(TInterFacedObject, Ih3API)
  private
  const
      H3_API_ENTRIES_MAX = 70;
      H3_API_ENTRIES: array[0.. H3_API_ENTRIES_MAX - 1] of string =
      ('latLngToCell','cellToLatLng','cellToBoundary',
      'maxGridDiskSize','gridDiskUnsafe','gridDiskDistancesUnsafe','gridDiskDistancesSafe',
      'gridDisksUnsafe','gridDisk','gridDiskDistances','gridRingUnsafe','maxPolygonToCellsSize',
      'polygonToCells','cellsToLinkedMultiPolygon','destroyLinkedMultiPolygon',
      'degsToRads','radsToDegs','greatCircleDistanceRads','greatCircleDistanceKm',
      'greatCircleDistanceM','getHexagonAreaAvgKm2','getHexagonAreaAvgM2','cellAreaRads2','cellAreaKm2',
      'cellAreaM2','getHexagonEdgeLengthAvgKm','getHexagonEdgeLengthAvgM','edgeLengthRads',
      'edgeLengthKm','edgeLengthM','getNumCells','res0CellCount','getRes0Cells',
      'pentagonCount','getPentagons','getResolution','getBaseCellNumber','stringToH3',
      'h3ToString','isValidCell','cellToParent','cellToChildrenSize','cellToChildren',
      'cellToCenterChild','cellToChildPos','childPosToCell','compactCells'
      ,'uncompactCellsSize','uncompactCells','isResClassIII','isPentagon','maxFaceCount',
      'getIcosahedronFaces','areNeighborCells','cellsToDirectedEdge','isValidDirectedEdge',
      'getDirectedEdgeOrigin','getDirectedEdgeDestination','directedEdgeToCells',
      'originToDirectedEdges','directedEdgeToBoundary','cellToVertex','cellToVertexes',
      'vertexToLatLng','isValidVertex','gridDistance','gridPathCellsSize','gridPathCells',
      'cellToLocalIj','localIjToCell'
    );
  var
      Fh3DllHandle: THandle;
      Fh3DllPath: string;
      Fh3MethodsBinded: Boolean;

      FlatLngToCell: function(const g: Ph3LatLng; res: Integer; pRetVal: Ph3Index): Th3Error; cdecl;
      FcellToLatLng: function(h3: Th3Index; g: Ph3LatLng): Th3Error; cdecl;
      FcellToBoundary: function(h3: Th3Index; gp: Ph3CellBoundary): Th3Error; cdecl;
      FmaxGridDiskSize: function(k: Integer; pRetVal: PInt64): Th3Error; cdecl;
      FgridDiskUnsafe: function(origin: Th3Index; k: Integer; pRetVal: Ph3Index): Th3Error; cdecl;
      FgridDiskDistancesUnsafe: function(origin: Th3Index; k: Integer; pRetVal: Ph3Index; distances: PInteger): Th3Error; cdecl;
      FgridDiskDistancesSafe: function(origin: Th3Index; k: Integer; pRetVal: Ph3Index; distances: PInteger): Th3Error; cdecl;
      FgridDisksUnsafe: function(h3Set: Ph3Index; length: Integer; k: Integer; pRetVal: Ph3Index): Th3Error; cdecl;
      FgridDisk: function(origin: Th3Index; k: Integer; pRetVal: Ph3Index): Th3Error; cdecl;
      FgridDiskDistances: function(origin: Th3Index; k: Integer; pRetVal: Ph3Index; distances: PInteger): Th3Error; cdecl;
      FgridRingUnsafe: function(origin: Th3Index; k: Integer; pRetVal: Ph3Index): Th3Error; cdecl;
      FmaxPolygonToCellsSize: function(const Th3GeoPolygon: Ph3GeoPolygon; res: Integer; flags: UInt32; pRetVal: PInt64): Th3Error; cdecl;
      FpolygonToCells: function(const Th3GeoPolygon: Ph3GeoPolygon; res: Integer; flags: UInt32; pRetVal: Ph3Index): Th3Error; cdecl;
      FcellsToLinkedMultiPolygon: function(const h3Set: Ph3Index; const numHexes: Integer; pRetVal: Ph3LinkedGeoPolygon): Th3Error; cdecl;
      FdestroyLinkedMultiPolygon: procedure(polygon: Ph3LinkedGeoPolygon); cdecl;
      FdegsToRads: function(degrees: Double): Double; cdecl;
      FradsToDegs: function(radians: Double): Double; cdecl;
      FgreatCircleDistanceRads: function(const a: Ph3LatLng; const b: Ph3LatLng): Double; cdecl;
      FgreatCircleDistanceKm: function(const a: Ph3LatLng; const b: Ph3LatLng): Double; cdecl;
      FgreatCircleDistanceM: function(const a: Ph3LatLng; const b: Ph3LatLng): Double; cdecl;
      FgetHexagonAreaAvgKm2: function(res: Integer; pRetVal: PDouble): Th3Error; cdecl;
      FgetHexagonAreaAvgM2: function(res: Integer; pRetVal: PDouble): Th3Error; cdecl;
      FcellAreaRads2: function(h: Th3Index; pRetVal: PDouble): Th3Error; cdecl;
      FcellAreaKm2: function(h: Th3Index; pRetVal: PDouble): Th3Error; cdecl;
      FcellAreaM2: function(h: Th3Index; pRetVal: PDouble): Th3Error; cdecl;
      FgetHexagonEdgeLengthAvgKm: function(res: Integer; pRetVal: PDouble): Th3Error; cdecl;
      FgetHexagonEdgeLengthAvgM: function(res: Integer; pRetVal: PDouble): Th3Error; cdecl;
      FedgeLengthRads: function(edge: Th3Index; length: PDouble): Th3Error; cdecl;
      FedgeLengthKm: function(edge: Th3Index; length: PDouble): Th3Error; cdecl;
      FedgeLengthM: function(edge: Th3Index; length: PDouble): Th3Error; cdecl;
      FgetNumCells: function(res: Integer; pRetVal: PInt64): Th3Error; cdecl;
      Fres0CellCount: function(): Integer; cdecl;
      FgetRes0Cells: function(pRetVal: Ph3Index): Th3Error; cdecl;
      FpentagonCount: function(): Integer; cdecl;
      FgetPentagons: function(res: Integer; pRetVal: Ph3Index): Th3Error; cdecl;
      FgetResolution: function(h: Th3Index): Integer; cdecl;
      FgetBaseCellNumber: function(h: Th3Index): Integer; cdecl;
      FstringToH3: function(const str: PUTF8Char; pRetVal: Ph3Index): Th3Error; cdecl;
      Fh3ToString: function(h: Th3Index; str: PUTF8Char; sz: NativeUInt): Th3Error; cdecl;
      FisValidCell: function(h: Th3Index): Integer; cdecl;
      FcellToParent: function(h: Th3Index; parentRes: Integer; parent: Ph3Index): Th3Error; cdecl;
      FcellToChildrenSize: function(h: Th3Index; childRes: Integer; pRetVal: PInt64): Th3Error; cdecl;
      FcellToChildren: function(h: Th3Index; childRes: Integer; children: Ph3Index): Th3Error; cdecl;
      FcellToCenterChild: function(h: Th3Index; childRes: Integer; child: Ph3Index): Th3Error; cdecl;
      FcellToChildPos: function(child: Th3Index; parentRes: Integer; pRetVal: PInt64): Th3Error; cdecl;
      FchildPosToCell: function(childPos: Int64; parent: Th3Index; childRes: Integer; child: Ph3Index): Th3Error; cdecl;
      FcompactCells: function(const h3Set: Ph3Index; compactedSet: Ph3Index; const numHexes: Int64): Th3Error; cdecl;
      FuncompactCellsSize: function(const compactedSet: Ph3Index; const numCompacted: Int64; const res: Integer; pRetVal: PInt64): Th3Error; cdecl;
      FuncompactCells: function(const compactedSet: Ph3Index; const numCompacted: Int64; outSet: Ph3Index; const numOut: Int64; const res: Integer): Th3Error; cdecl;
      FisResClassIII: function(h: Th3Index): Integer; cdecl;
      FisPentagon: function(h: Th3Index): Integer; cdecl;
      FmaxFaceCount: function(h3: Th3Index; pRetVal: PInteger): Th3Error; cdecl;
      FgetIcosahedronFaces: function(h3: Th3Index; pRetVal: PInteger): Th3Error; cdecl;
      FareNeighborCells: function(origin: Th3Index; destination: Th3Index; pRetVal: PInteger): Th3Error; cdecl;
      FcellsToDirectedEdge: function(origin: Th3Index; destination: Th3Index; pRetVal: Ph3Index): Th3Error; cdecl;
      FisValidDirectedEdge: function(edge: Th3Index): Integer; cdecl;
      FgetDirectedEdgeOrigin: function(edge: Th3Index; pRetVal: Ph3Index): Th3Error; cdecl;
      FgetDirectedEdgeDestination: function(edge: Th3Index; pRetVal: Ph3Index): Th3Error; cdecl;
      FdirectedEdgeToCells: function(edge: Th3Index; originDestination: Ph3Index): Th3Error; cdecl;
      ForiginToDirectedEdges: function(origin: Th3Index; edges: Ph3Index): Th3Error; cdecl;
      FdirectedEdgeToBoundary: function(edge: Th3Index; gb: Ph3CellBoundary): Th3Error; cdecl;
      FcellToVertex: function(origin: Th3Index; vertexNum: Integer; pRetVal: Ph3Index): Th3Error; cdecl;
      FcellToVertexes: function(origin: Th3Index; vertexes: Ph3Index): Th3Error; cdecl;
      FvertexToLatLng: function(vertex: Th3Index; point: Ph3LatLng): Th3Error; cdecl;
      FisValidVertex: function(vertex: Th3Index): Integer; cdecl;
      FgridDistance: function(origin: Th3Index; h3: Th3Index; distance: PInt64): Th3Error; cdecl;
      FgridPathCellsSize: function(start: Th3Index; &end: Th3Index; size: PInt64): Th3Error; cdecl;
      FgridPathCells: function(start: Th3Index; &end: Th3Index; pRetVal: Ph3Index): Th3Error; cdecl;
      FcellToLocalIj: function(origin: Th3Index; h3: Th3Index; mode: UInt32; pRetVal: Ph3CoordIJ): Th3Error; cdecl;
      FlocalIjToCell: function(origin: Th3Index; const ij: Ph3CoordIJ; mode: UInt32; pRetVal: Ph3Index): Th3Error; cdecl;
    class var [Volatile] FInstance: TObject;
    procedure BindMethods;
    procedure CheckMethod(const AAddress: PPointer);
    procedure LoadApiLibrary;
    function MethodAvailable(AAdress: PPointer; out MethodName: string): Boolean;
    procedure ThisMethodNotAvailable(const AMethodName: string);
  public
    constructor Create(const ADllPath: string);
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function areNeighborCells(origin: Th3Index; destination: Th3Index; pRetVal: PInteger): Th3Error;
    /// <summary>
    ///   Area of H3 cell in kilometers^2.
    /// </summary>
    /// <param name="h">
    ///   directed edge
    /// </param>
    /// <param name="pRetVal">
    ///   length in km^2
    /// </param>
    function cellAreaKm2(h: Th3Index; pRetVal: PDouble): Th3Error;
    /// <summary>
    ///   Area of H3 cell in meters^2.
    /// </summary>
    /// <param name="h">
    ///   directed edge
    /// </param>
    /// <param name="pRetVal">
    ///   length in m^2 <br />
    /// </param>
    function cellAreaM2(h: Th3Index; pRetVal: PDouble): Th3Error;
    /// <summary>
    ///   Length of a directed edge in radians.
    /// </summary>
    /// <param name="h">
    ///   edge H3 directed edge
    /// </param>
    /// <param name="pRetVal">
    ///   length in radians^2
    /// </param>
    function cellAreaRads2(h: Th3Index; pRetVal: PDouble): Th3Error;
    /// <summary>
    ///   Returns a directed edge H3 index based on the provided origin and destination
    /// </summary>
    /// <param name="origin">
    ///   The origin H3 hexagon index <br />
    /// </param>
    /// <param name="destination">
    ///   The destination H3 hexagon index <br />
    /// </param>
    /// <param name="pRetVal">
    ///   Thedirected edge H3Index or H3_NULL onfailure.
    /// </param>
    /// <returns>
    ///   E_SUCCESS on success else error code
    /// </returns>
    function cellsToDirectedEdge(origin: Th3Index; destination: Th3Index; pRetVal: Ph3Index): Th3Error;
    /// <summary>
    ///   Create a LinkedGeoPolygon describing the outline(s) of a set of hexagons. Polygon outlines will follow
    ///   GeoJSON MultiPolygon order: Each polygon will have one outer loop, which is first in the list,followed by any
    ///   holes.
    /// </summary>
    /// <param name="h3Set">
    ///   Set of hexagons
    /// </param>
    /// <param name="numHexes">
    ///   Number of hexagons in set
    /// </param>
    /// <param name="pRetVal">
    ///   Output polygon
    /// </param>
    /// <remarks>
    ///   It is the responsibility of the caller to calldestroyLinkedMultiPolygon on the populated linked geo
    ///   structure, or the memory for that structurewill not be freed. <br />It is expected that all hexagons in the
    ///   set have the sameresolution and that the set contains no duplicates. Behavior is undefined if duplicates or
    ///   multiple resolutions are present, and the algorithm may produce unexpected or invalid output.
    /// </remarks>
    function cellsToLinkedMultiPolygon(const h3Set: Ph3Index; const numHexes: Integer; pRetVal: Ph3LinkedGeoPolygon): Th3Error;
    function cellToBoundary(h: Th3Index; gp: Ph3CellBoundary): Th3Error; overload;
    /// <summary>
    ///   Determines the cell boundary in spherical coordinates for an H3 index.
    /// </summary>
    /// <param name="h">
    ///   The H3 index.
    /// </param>
    /// <param name="CellBoundary">
    ///   The boundary of the H3 cell in spherical coordinates.
    /// </param>
    function CellToBoundary(const h: Th3Index;  var CellBoundary: TArray<Th3LatLng>): Boolean; overload;
    function cellToCenterChild(h: Th3Index; childRes: Integer; child: Ph3Index): Th3Error;
    function cellToChildPos(child: Th3Index; parentRes: Integer; pRetVal: PInt64): Th3Error;
    function cellToChildren(h: Th3Index; childRes: Integer; children: Ph3Index): Th3Error;
    function cellToChildrenSize(h: Th3Index; childRes: Integer; pRetVal: PInt64): Th3Error;
    function CellToLatLng(const h: Th3Index; var Lat,Lng: Double): Boolean;
    function cellToLocalIj(origin: Th3Index; h3: Th3Index; mode: UInt32; pRetVal: Ph3CoordIJ): Th3Error;
    function cellToParent(h: Th3Index; parentRes: Integer; parent: Ph3Index): Th3Error;
    function cellToVertex(origin: Th3Index; vertexNum: Integer; pRetVal: Ph3Index): Th3Error;
    function cellToVertexes(origin: Th3Index; vertexes: Ph3Index): Th3Error;
    function childPosToCell(childPos: Int64; parent: Th3Index; childRes: Integer; child: Ph3Index): Th3Error;
    function compactCells(const h3Set: Ph3Index; compactedSet: Ph3Index; const numHexes: Int64): Th3Error; overload;
    function CompactCells(const Source: TArray<Th3Index>; var Compacted: TArray<Th3Index>): Boolean; overload;
    function degsToRads(degrees: Double): Double;
    procedure destroyLinkedMultiPolygon(polygon: Ph3LinkedGeoPolygon);
    function directedEdgeToBoundary(edge: Th3Index; gb: Ph3CellBoundary): Th3Error;
    function directedEdgeToCells(edge: Th3Index; originDestination: Ph3Index): Th3Error;
    function edgeLengthKm(edge: Th3Index; length: PDouble): Th3Error;
    function edgeLengthM(edge: Th3Index; length: PDouble): Th3Error;
    function edgeLengthRads(edge: Th3Index; length: PDouble): Th3Error;
    function getBaseCellNumber(h: Th3Index): Integer;
    function getDirectedEdgeDestination(edge: Th3Index; pRetVal: Ph3Index): Th3Error;
    function getDirectedEdgeOrigin(edge: Th3Index; pRetVal: Ph3Index): Th3Error;
    function getHexagonAreaAvgKm2(res: Integer; pRetVal: PDouble): Th3Error;
    function getHexagonAreaAvgM2(res: Integer; pRetVal: PDouble): Th3Error;
    function getHexagonEdgeLengthAvgKm(res: Integer; pRetVal: PDouble): Th3Error;
    function getHexagonEdgeLengthAvgM(res: Integer; pRetVal: PDouble): Th3Error;
    function getIcosahedronFaces(h3: Th3Index; pRetVal: PInteger): Th3Error;
    function getNumCells(res: Integer; pRetVal: PInt64): Th3Error;
    function getPentagons(res: Integer; pRetVal: Ph3Index): Th3Error;
    function getRes0Cells(pRetVal: Ph3Index): Th3Error;
    function getResolution(h: Th3Index): Integer;
    function greatCircleDistanceKm(const a: Ph3LatLng; const b: Ph3LatLng): Double;
    function greatCircleDistanceM(const a: Ph3LatLng; const b: Ph3LatLng): Double;
    function greatCircleDistanceRads(const a: Ph3LatLng; const b: Ph3LatLng): Double;
    function gridDisk(origin: Th3Index; k: Integer; pRetVal: Ph3Index): Th3Error;
    function gridDiskDistances(origin: Th3Index; k: Integer; pRetVal: Ph3Index; distances: PInteger): Th3Error;
    function gridDiskDistancesSafe(origin: Th3Index; k: Integer; pRetVal: Ph3Index; distances: PInteger): Th3Error;
    function gridDiskDistancesUnsafe(origin: Th3Index; k: Integer; pRetVal: Ph3Index; distances: PInteger): Th3Error;
    function gridDisksUnsafe(h3Set: Ph3Index; length: Integer; k: Integer; pRetVal: Ph3Index): Th3Error;
    function gridDiskUnsafe(origin: Th3Index; k: Integer; pRetVal: Ph3Index): Th3Error;
    function gridDistance(origin: Th3Index; h3: Th3Index; distance: PInt64): Th3Error;
    function gridPathCells(start: Th3Index; &end: Th3Index; pRetVal: Ph3Index): Th3Error;
    function gridPathCellsSize(start: Th3Index; &end: Th3Index; size: PInt64): Th3Error;
    function gridRingUnsafe(origin: Th3Index; k: Integer; pRetVal: Ph3Index): Th3Error;
    function h3ToString(h: Th3Index; var str: string): Th3Error;
    function isPentagon(h: Th3Index): Integer;
    function isResClassIII(h: Th3Index): Integer;
    function isValidCell(h: Th3Index): Integer;
    function isValidDirectedEdge(edge: Th3Index): Integer;
    function isValidVertex(vertex: Th3Index): Integer;
    function LatLngToCell(const Lat,Lng: Double; Resolution: Integer; var h: Th3Index): Boolean;
    function localIjToCell(origin: Th3Index; const ij: Ph3CoordIJ; mode: UInt32; pRetVal: Ph3Index): Th3Error;
    function maxFaceCount(h3: Th3Index; pRetVal: PInteger): Th3Error;
    function maxGridDiskSize(k: Integer; pRetVal: PInt64): Th3Error;
    function maxPolygonToCellsSize(const geoPolygon: Ph3GeoPolygon; res: Integer; flags: UInt32; pRetVal: PInt64): Th3Error;
    function originToDirectedEdges(origin: Th3Index; edges: Ph3Index): Th3Error;
    function pentagonCount(): Integer;
    function polygonToCells(const geoPolygon: Ph3GeoPolygon; res: Integer; flags: UInt32; pRetVal: Ph3Index): Th3Error;
    function radsToDegs(radians: Double): Double;
    function res0CellCount(): Integer;
    function stringToH3(const str: string; var cell: Th3Index): Th3Error;
    function Succeeded(Err: Th3Error): Boolean;
    function uncompactCells(const compactedSet: Ph3Index; const numCompacted: Int64; outSet: Ph3Index; const numOut: Int64; const res: Integer): Th3Error;
    function uncompactCellsSize(const compactedSet: Ph3Index; const numCompacted: Int64; const res: Integer; pRetVal: PInt64): Th3Error;
    function vertexToLatLng(vertex: Th3Index; var lat,lng: double): Th3Error;
    class function NewInstance: TObject; override;
    property DllPath: string read Fh3DllPath;
  end;


resourcestring
  rsErrorH3DllNotFound = 'can`t find h3 api dll';
  rsErrorH3DllLoadFailed = 'can`t load h3 api dll:' + slinebreak+ '%s';
  rsErrorH3MethodUnavaible = '%s - %s method unavailable';

implementation

{$region '  Th3ErrorHelper'}
{ Th3ErrorHelper }

function Th3ErrorHelper.Succeed: Boolean;
begin
 Result := Self = Th3Error(Th3ErrorCodes.E_SUCCESS);
end;
{$endregion}

{$region '  Th3IndexHelper'}
{ Th3IndexHelper }

function Th3IndexHelper.GetBaseCell: Integer;
// #define H3_GET_BASE_CELL(h3) ((int)((((h3)&H3_BC_MASK) >> H3_BC_OFFSET)))
begin
  Result := Integer((Self and H3_BC_MASK) shr H3_BC_OFFSET);
end;

function Th3IndexHelper.GetDigit(AResolution: Integer): Integer;
(*
#define H3_GET_INDEX_DIGIT(h3, res) \
    ((Direction)((((h3) >> ((MAX_H3_RES - (res)) * H3_PER_DIGIT_OFFSET)) & H3_DIGIT_MASK)))
*)
begin
  AResolution := EnsureRange(AResolution,H3_RES_MIN,H3_RES_MAX);
  Result := (Self shl ((H3_RES_MAX - AResolution)*H3_PER_DIGIT_OFFSET)) and H3_DIGIT_MASK;
  Result := EnsureRange(Result, H3_DIRECTION_MIN, H3_INVALID_DIGIT);
end;

function Th3IndexHelper.GetCellMode: Integer;
// #define H3_GET_MODE(h3) ((int)((((h3)&H3_MODE_MASK) >> H3_MODE_OFFSET)))
begin
  Result := Integer((Self and H3_MODE_MASK) shr H3_MODE_OFFSET);
end;

function Th3IndexHelper.GetReservedBits: Integer;
(*
#define H3_GET_RESERVED_BITS(h3) \
    ((int)((((h3)&H3_RESERVED_MASK) >> H3_RESERVED_OFFSET)))
*)
begin
  Result := Integer((Self and H3_RESERVED_MASK) shr H3_RESERVED_OFFSET);
end;

function Th3IndexHelper.GetResolution: Integer;
// #define H3_GET_RESOLUTION(h3) ((int)((((h3)&H3_RES_MASK) >> H3_RES_OFFSET)))
begin
  Result := Integer((Self and H3_RES_MASK) shr H3_RES_OFFSET);
end;
procedure Th3IndexHelper.SetBaseCell(Value: Integer);
(*
#define H3_SET_BASE_CELL(h3, bc) \
    (h3) = (((h3)&H3_BC_MASK_NEGATIVE) | (((uint64_t)(bc)) << H3_BC_OFFSET))
*)
begin
  Value := EnsureRange(Value,0,H3_NUM_BASE_CELLS);
  Self := (Self and H3_BC_MASK_NEGATIVE) or (Uint64(Value) shl H3_BC_OFFSET);
end;

procedure Th3IndexHelper.SetCellMode(AMode: Integer);
(*
#define H3_SET_MODE(h3, v) \
    (h3) = (((h3)&H3_MODE_MASK_NEGATIVE) | (((uint64_t)(v)) << H3_MODE_OFFSET))
*)
begin
  AMode := EnsureRange(AMode, H3_CELL_MODE,H3_VERTEX_MODE);
  Self := (Self and H3_MODE_MASK_NEGATIVE) or (Uint64(AMode) shl H3_MODE_OFFSET);
end;

procedure Th3IndexHelper.SetDigit(AResolution, AValue: Integer);
(*
#define H3_SET_INDEX_DIGIT(h3, res, digit)                                  \
    (h3) = (((h3) & ~((H3_DIGIT_MASK                                        \
                       << ((MAX_H3_RES - (res)) * H3_PER_DIGIT_OFFSET)))) | \
            (((uint64_t)(digit))                                            \
             << ((MAX_H3_RES - (res)) * H3_PER_DIGIT_OFFSET)))
*)
begin
  // Self := (Self and not (H3_DIGIT_MASK shl ((H3_RES_MAX - (AResolution)) * H3_PER_DIGIT_OFFSET))) or Uint64(AValue) shl ((H3_RES_MAX - (AValue)) * H3_PER_DIGIT_OFFSET);
  AResolution := (H3_RES_MAX - EnsureRange(AResolution,H3_RES_MIN,H3_RES_MAX)) * H3_PER_DIGIT_OFFSET;
  Self := (Self and not H3_DIGIT_MASK shl AResolution) or (Uint64(AValue) shl AResolution)
end;

procedure Th3IndexHelper.SetResolution(Value: Integer);
//#define H3_SET_RESOLUTION(h3, res) \
//    (h3) = (((h3)&H3_RES_MASK_NEGATIVE) | (((uint64_t)(res)) << H3_RES_OFFSET))
begin
  Value := EnsureRange(Value,H3_RES_MIN,H3_RES_MAX);
  Self := (Self and H3_RES_MASK_NEGATIVE) or (UInt64(Value) shl H3_RES_OFFSET);
end;
{$endregion}

{$region '  Th3LatLng'}

{ Th3LatLng }

class function Th3LatLng.Create(const lat, lng: double): Th3LatLng;
begin
  Result.LatitudeInRadians := DegToRad(lat);
  Result.LongitudeInRadians := DegToRad(lng);
end;

function Th3LatLng.Latitude: Double;
begin
  Result := RadToDeg(LatitudeInRadians);
end;

function Th3LatLng.Longitude: Double;
begin
  Result := RadToDeg(LongitudeInRadians);
end;

constructor Th3Api.Create(const ADllPath: string);
begin
  inherited Create;
  Fh3DllHandle := 0;
  Fh3MethodsBinded := False;
  Fh3DllPath := ADllPath;
end;

destructor Th3Api.Destroy;
begin
  if Fh3DllHandle > 0 then
    FreeLibrary(Fh3DllHandle);
  Fh3DllHandle := 0;
  inherited;
end;

procedure Th3Api.AfterConstruction;
begin
  inherited;
end;

function Th3Api.areNeighborCells(origin, destination: Th3Index; pRetVal: PInteger): Th3Error;
begin
  CheckMethod(@@FareNeighborCells);
  Result := FareNeighborCells(origin,destination,pRetVal);
end;

procedure Th3Api.BeforeDestruction;
begin
  inherited;

end;

procedure Th3Api.BindMethods;
var
  methods: PTypeTable;
  i: Integer;
begin
  LoadApiLibrary;
  if not Fh3MethodsBinded then begin
    methods := @@Self.FlatLngToCell;
    for i := 0 to High(H3_API_ENTRIES) do
      Methods^[i] := GetProcAddress(Fh3DllHandle, PChar(H3_API_ENTRIES[i]));
    Fh3MethodsBinded := True;
  end;
end;

function Th3Api.cellAreaKm2(h: Th3Index; pRetVal: PDouble): Th3Error;
begin
  CheckMethod(@@FcellAreaKm2);
  Result := FcellAreaKm2(h,pRetVal);
end;

function Th3Api.cellAreaM2(h: Th3Index; pRetVal: PDouble): Th3Error;
begin
  CheckMethod(@@FcellAreaM2);
  Result := FcellAreaM2(h,pRetVal);
end;

function Th3Api.cellAreaRads2(h: Th3Index; pRetVal: PDouble): Th3Error;
begin
  CheckMethod(@@FcellAreaRads2);
  Result := FcellAreaRads2(h,pRetVal);
end;

function Th3Api.cellsToDirectedEdge(origin, destination: Th3Index; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FcellsToDirectedEdge);
  Result := FcellsToDirectedEdge(origin,destination,pRetVal);
end;

function Th3Api.cellsToLinkedMultiPolygon(const h3Set: Ph3Index; const numHexes: Integer; pRetVal: Ph3LinkedGeoPolygon): Th3Error;
begin
  CheckMethod(@@FcellsToLinkedMultiPolygon);
  Result := FcellsToLinkedMultiPolygon(h3Set,numHexes,pRetVal);
end;

function Th3Api.cellToBoundary(h: Th3Index; gp: Ph3CellBoundary): Th3Error;
begin
  CheckMethod(@@FcellToBoundary);
  Result := FcellToBoundary(h,gp);
end;

function Th3Api.cellToBoundary(const h: Th3Index; var CellBoundary: TArray<Th3LatLng>): Boolean;
var gp: Th3CellBoundary; i: integer;
begin
  Result := cellToBoundary(h,@gp).Succeed;
  if Result then
  begin
    SetLength(CellBoundary, gp.numVerts);
    for i := 0 to gp.numVerts -1 do
      CellBoundary[i] := gp.verts[i];
  end
  else
    CellBoundary := nil;
end;

function Th3Api.cellToCenterChild(h: Th3Index; childRes: Integer; child: Ph3Index): Th3Error;
begin
  CheckMethod(@@FcellToCenterChild);
  Result := FcellToCenterChild(h,childRes,child);
end;

function Th3Api.cellToChildPos(child: Th3Index; parentRes: Integer; pRetVal: PInt64): Th3Error;
begin
  CheckMethod(@@FcellToChildPos);
  Result := FcellToChildPos(child,parentRes,pRetVal);
end;

function Th3Api.cellToChildren(h: Th3Index; childRes: Integer; children: Ph3Index): Th3Error;
begin
  CheckMethod(@@FcellToChildren);
  Result := FcellToChildren(h,childRes,children);
end;

function Th3Api.cellToChildrenSize(h: Th3Index; childRes: Integer; pRetVal: PInt64): Th3Error;
begin
  CheckMethod(@@FcellToChildrenSize);
  Result := FcellToChildrenSize(h,childRes,pRetVal);
end;

function Th3Api.CellToLatLng(const h: Th3Index; var Lat,Lng: Double): Boolean;
var g: Th3LatLng;
begin
  CheckMethod(@@FcellToLatLng);
  Result := FcellToLatLng(h,@g).Succeed;
  if Result then
  begin
    Result := True;
    Lat := g.Latitude;
    Lng := g.Longitude;
  end
  else
  begin
    Lat := Lat.NaN;
    Lng := Lat;
  end;
end;

function Th3Api.cellToLocalIj(origin, h3: Th3Index; mode: UInt32; pRetVal: Ph3CoordIJ): Th3Error;
begin
  CheckMethod(@@FcellToLocalIj);
  Result := FcellToLocalIj(origin,h3,mode,pRetVal);
end;

function Th3Api.cellToParent(h: Th3Index; parentRes: Integer; parent: Ph3Index): Th3Error;
begin
  CheckMethod(@@FcellToParent);
  Result := FcellToParent(h,parentRes,parent);
end;

function Th3Api.cellToVertex(origin: Th3Index; vertexNum: Integer; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FcellToVertex);
  Result := FcellToVertex(origin,vertexNum,pRetVal);
end;

function Th3Api.cellToVertexes(origin: Th3Index; vertexes: Ph3Index): Th3Error;
begin
  CheckMethod(@@FcellToVertexes);
  Result := FcellToVertexes(origin,vertexes);
end;

procedure Th3Api.CheckMethod(const AAddress: PPointer);
var methodName: string;
begin
  if not MethodAvailable(AAddress, MethodName) then
    ThisMethodNotAvailable(MethodName);
end;

function Th3Api.childPosToCell(childPos: Int64; parent: Th3Index; childRes: Integer; child: Ph3Index): Th3Error;
begin
  CheckMethod(@@FchildPosToCell);
  Result := FchildPosToCell(childPos,parent,childRes,child);
end;

function Th3Api.CompactCells(const Source: TArray<Th3Index>; var Compacted: TArray<Th3Index>): Boolean;
var compactedSize: Int64;
begin
{$IFOPT R+}{$DEFINE RANGEON}{$R-}{$ELSE}{$UNDEF RANGEON}{$ENDIF}
  compactedSize := Length(Source);
  Result := compactedSize > 0;
  Setlength(Compacted,compactedSize);
  Result := Result and compactCells(@Source[0],@Compacted[0],compactedSize).Succeed;
  if not Result then
    Compacted := nil;
{$IFDEF RANGEON}{$R+}{$UNDEF RANGEON}{$ENDIF}
end;

function Th3Api.compactCells(const h3Set: Ph3Index; compactedSet: Ph3Index; const numHexes: Int64): Th3Error;
begin
  CheckMethod(@@FcompactCells);
  Result := FcompactCells(h3Set,compactedSet,numHexes);
end;

function Th3Api.degsToRads(degrees: Double): Double;
begin
  CheckMethod(@@FdegsToRads);
  Result := FdegsToRads(degrees);
end;

procedure Th3Api.destroyLinkedMultiPolygon(polygon: Ph3LinkedGeoPolygon);
begin
  CheckMethod(@@FdestroyLinkedMultiPolygon);
  FdestroyLinkedMultiPolygon(polygon);
end;

function Th3Api.directedEdgeToBoundary(edge: Th3Index; gb: Ph3CellBoundary): Th3Error;
begin
  CheckMethod(@@FdirectedEdgeToBoundary);
  Result:= FdirectedEdgeToBoundary(edge,gb);
end;

function Th3Api.directedEdgeToCells(edge: Th3Index; originDestination: Ph3Index): Th3Error;
begin
  CheckMethod(@@FdirectedEdgeToCells);
  Result:= FdirectedEdgeToCells(edge,originDestination);
end;

function Th3Api.edgeLengthKm(edge: Th3Index; length: PDouble): Th3Error;
begin
  CheckMethod(@@FedgeLengthKm);
  Result:= FedgeLengthKm(edge,length);
end;

function Th3Api.edgeLengthM(edge: Th3Index; length: PDouble): Th3Error;
begin
  CheckMethod(@@FedgeLengthM);
  Result:= FedgeLengthM(edge,length);
end;

function Th3Api.edgeLengthRads(edge: Th3Index; length: PDouble): Th3Error;
begin
  CheckMethod(@@FedgeLengthRads);
  Result:= FedgeLengthRads(edge,length);
end;

function Th3Api.getBaseCellNumber(h: Th3Index): Integer;
begin
  CheckMethod(@@FgetBaseCellNumber);
  Result:= FgetBaseCellNumber(h);
end;

function Th3Api.getDirectedEdgeDestination(edge: Th3Index; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FgetDirectedEdgeDestination);
  Result:= FgetDirectedEdgeDestination(edge,pRetVal);
end;

function Th3Api.getDirectedEdgeOrigin(edge: Th3Index; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FgetDirectedEdgeOrigin);
  Result:= FgetDirectedEdgeOrigin(edge,pRetVal);
end;

function Th3Api.getHexagonAreaAvgKm2(res: Integer; pRetVal: PDouble): Th3Error;
begin
  CheckMethod(@@FgetHexagonAreaAvgKm2);
  Result:= FgetHexagonAreaAvgKm2(res,pRetVal);
end;

function Th3Api.getHexagonAreaAvgM2(res: Integer; pRetVal: PDouble): Th3Error;
begin
  CheckMethod(@@FgetHexagonAreaAvgM2);
  Result:= FgetHexagonAreaAvgM2(res,pRetVal);
end;

function Th3Api.getHexagonEdgeLengthAvgKm(res: Integer; pRetVal: PDouble): Th3Error;
begin
  CheckMethod(@@FgetHexagonEdgeLengthAvgKm);
  Result:= FgetHexagonEdgeLengthAvgKm(res,pRetVal);
end;

function Th3Api.getHexagonEdgeLengthAvgM(res: Integer; pRetVal: PDouble): Th3Error;
begin
  CheckMethod(@@FgetHexagonEdgeLengthAvgM);
  Result:= FgetHexagonEdgeLengthAvgM(res,pRetVal);
end;

function Th3Api.getIcosahedronFaces(h3: Th3Index; pRetVal: PInteger): Th3Error;
begin
  CheckMethod(@@FgetIcosahedronFaces);
  Result:= FgetIcosahedronFaces(h3,pRetVal);
end;

function Th3Api.getNumCells(res: Integer; pRetVal: PInt64): Th3Error;
begin
  CheckMethod(@@FgetNumCells);
  Result:= FgetNumCells(res,pRetVal);
end;

function Th3Api.getPentagons(res: Integer; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FgetPentagons);
  Result:= FgetPentagons(res,pRetVal);
end;

function Th3Api.getRes0Cells(pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FgetRes0Cells);
  Result:= FgetRes0Cells(pRetVal);
end;

function Th3Api.getResolution(h: Th3Index): Integer;
begin
  CheckMethod(@@FgetResolution);
  Result:= FgetResolution(h);
end;

function Th3Api.greatCircleDistanceKm(const a, b: Ph3LatLng): Double;
begin
  CheckMethod(@@FgreatCircleDistanceKm);
  Result:= FgreatCircleDistanceKm(a,b);
end;

function Th3Api.greatCircleDistanceM(const a, b: Ph3LatLng): Double;
begin
  CheckMethod(@@FgreatCircleDistanceM);
  Result:= FgreatCircleDistanceM(a,b);
end;

function Th3Api.greatCircleDistanceRads(const a, b: Ph3LatLng): Double;
begin
  CheckMethod(@@FgreatCircleDistanceRads);
  Result:= FgreatCircleDistanceRads(a,b);
end;

function Th3Api.gridDisk(origin: Th3Index; k: Integer; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FgridDisk);
  Result:= FgridDisk(origin,k,pRetVal);
end;

function Th3Api.gridDiskDistances(origin: Th3Index; k: Integer; pRetVal: Ph3Index; distances: PInteger): Th3Error;
begin
  CheckMethod(@@FgridDiskDistances);
  Result:= FgridDiskDistances(origin,k,pRetVal,distances);
end;

function Th3Api.gridDiskDistancesSafe(origin: Th3Index; k: Integer; pRetVal: Ph3Index; distances: PInteger): Th3Error;
begin
  CheckMethod(@@FgridDiskDistancesSafe);
  Result:= FgridDiskDistancesSafe(origin,k,pRetVal,distances);
end;

function Th3Api.gridDiskDistancesUnsafe(origin: Th3Index; k: Integer; pRetVal: Ph3Index; distances: PInteger): Th3Error;
begin
  CheckMethod(@@FgridDiskDistancesUnsafe);
  Result:= FgridDiskDistancesUnsafe(origin,k,pRetVal,distances);
end;

function Th3Api.gridDisksUnsafe(h3Set: Ph3Index; length, k: Integer; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FgridDisksUnsafe);
  Result:= FgridDisksUnsafe(h3Set,length, k,pRetVal);
end;

function Th3Api.gridDiskUnsafe(origin: Th3Index; k: Integer; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FgridDiskUnsafe);
  Result:= FgridDiskUnsafe(origin,k,pRetVal);
end;

function Th3Api.gridDistance(origin, h3: Th3Index; distance: PInt64): Th3Error;
begin
  CheckMethod(@@FgridDistance);
  Result:= FgridDistance(origin,h3,distance);
end;

function Th3Api.gridPathCells(start, &end: Th3Index; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FgridPathCells);
  Result:= FgridPathCells(start,&end,pRetVal);
end;

function Th3Api.gridPathCellsSize(start, &end: Th3Index; size: PInt64): Th3Error;
begin
  CheckMethod(@@FgridPathCellsSize);
  Result:= FgridPathCellsSize(start,&end,size);
end;

function Th3Api.gridRingUnsafe(origin: Th3Index; k: Integer; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FgridRingUnsafe);
  Result:= FgridRingUnsafe(origin,k,pRetVal);
end;

function Th3Api.h3ToString(h: Th3Index; var str: string): Th3Error;
const h3MinSize = 20;
var buffer: TBytes;
begin
  CheckMethod(@@Fh3ToString);
  SetLength(buffer,h3MinSize);
  Result:= Fh3ToString(h,@buffer[0],h3MinSize);
  if Result = Th3Error(Ord(Th3ErrorCodes.E_SUCCESS)) then
    str := StringOf(buffer)
  else
    str := '';
end;

function Th3Api.isPentagon(h: Th3Index): Integer;
begin
  CheckMethod(@@FisPentagon);
  Result:= FisPentagon(h);
end;

function Th3Api.isResClassIII(h: Th3Index): Integer;
begin
  CheckMethod(@@FisResClassIII);
  Result:= FisResClassIII(h);
end;

function Th3Api.isValidCell(h: Th3Index): Integer;
begin
  CheckMethod(@@FisValidCell);
  Result:= FisValidCell(h);
end;

function Th3Api.isValidDirectedEdge(edge: Th3Index): Integer;
begin
  CheckMethod(@@FisValidDirectedEdge);
  Result:= FisValidDirectedEdge(edge);
end;

function Th3Api.isValidVertex(vertex: Th3Index): Integer;
begin
  CheckMethod(@@FisValidVertex);
  Result:= FisValidVertex(vertex);
end;

function Th3Api.LatLngToCell(const lat,lng: Double; resolution: Integer; var h: Th3Index): Boolean;
var g: Th3LatLng;
begin
  CheckMethod(@@FlatLngToCell);
  g := Th3LatLng.Create(lat,lng);
  Result := FlatLngToCell(@g,resolution,@h).Succeed;
end;

procedure Th3Api.LoadApiLibrary;
begin
  if Fh3DllHandle <> 0 then Exit;

  if Fh3DllPath.IsEmpty then
    Fh3DllPath := GetEnvironmentVariable(H3_DLL_PATH);
  if Fh3DllPath.IsEmpty then
    Fh3DllPath := h3dllDefname;

  if not FileExists(Fh3DllPath) then
    raise EFileNotFoundException.CreateRes(@rsErrorH3DllNotFound,Fh3DllPath);

  Fh3DllHandle := SafeLoadLibrary(Fh3DllPath);
  if Fh3DllHandle = 0 then
    raise h3Error.CreateResFmt(@rsErrorH3DllLoadFailed,[SysErrorMessage(GetLastError)]);
end;

function Th3Api.localIjToCell(origin: Th3Index; const ij: Ph3CoordIJ; mode: UInt32; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FlocalIjToCell);
  Result:= FlocalIjToCell(origin,ij,mode,pRetVal);
end;

function Th3Api.maxFaceCount(h3: Th3Index; pRetVal: PInteger): Th3Error;
begin
  CheckMethod(@@FmaxFaceCount);
  Result:= FmaxFaceCount(h3,pRetVal);
end;

function Th3Api.maxGridDiskSize(k: Integer; pRetVal: PInt64): Th3Error;
begin
  CheckMethod(@@FmaxGridDiskSize);
  Result:= FmaxGridDiskSize(k,pRetVal);
end;

function Th3Api.maxPolygonToCellsSize(const GeoPolygon: Ph3GeoPolygon; res: Integer; flags: UInt32; pRetVal: PInt64): Th3Error;
begin
  CheckMethod(@@FmaxPolygonToCellsSize);
  Result:= FmaxPolygonToCellsSize(GeoPolygon,res,flags,pRetVal);
end;

function Th3Api.MethodAvailable(AAdress: PPointer; out MethodName: string): Boolean;
var i: integer;
begin
  BindMethods;
  Result := Assigned(AAdress^);
  if not Result then
  begin
    i := (UIntPtr(AAdress) - UIntPtr(@@Self.FlatLngToCell)) div SizeOf(Pointer);
    if (i > -1) and (i < High(H3_API_ENTRIES)) then
      MethodName := H3_API_ENTRIES[i]
  end;
end;

class function Th3Api.NewInstance: TObject;
var
  temp: TObject;
begin
  if FInstance = nil then
  begin
    temp := inherited NewInstance;
    if TInterlocked.CompareExchange(FInstance,temp,nil) <> nil then
      temp.FreeInstance;
  end;
  Result := FInstance;
end;

function Th3Api.originToDirectedEdges(origin: Th3Index; edges: Ph3Index): Th3Error;
begin
  CheckMethod(@@ForiginToDirectedEdges);
  Result:= ForiginToDirectedEdges(origin,edges);
end;

function Th3Api.pentagonCount: Integer;
begin
  CheckMethod(@@FpentagonCount);
  Result:= FpentagonCount();
end;

function Th3Api.polygonToCells(const geoPolygon: Ph3GeoPolygon; res: Integer; flags: UInt32; pRetVal: Ph3Index): Th3Error;
begin
  CheckMethod(@@FpolygonToCells);
  Result:= FpolygonToCells(geoPolygon,res,flags,pRetVal);
end;

function Th3Api.radsToDegs(radians: Double): Double;
begin
  CheckMethod(@@FradsToDegs);
  Result:= FradsToDegs(radians);
end;

function Th3Api.res0CellCount: Integer;
begin
  CheckMethod(@@Fres0CellCount);
  Result:= Fres0CellCount;
end;

function Th3Api.stringToH3(const str: string; var cell: Th3Index): Th3Error;
var
  buffer: TBytes;
begin
  CheckMethod(@@FstringToH3);
  buffer := TEncoding.UTF8.GetBytes(str);
  Result:= FstringToH3(@buffer[0],@cell);
end;

function Th3Api.Succeeded(Err: Th3Error): Boolean;
begin
  Result := Err.Succeed;
end;

procedure Th3Api.ThisMethodNotAvailable(const AMethodName: string);
begin
  raise h3Error.CreateResFmt(@rsErrorH3MethodUnavaible,[Th3Api.ClassName,AMethodName]);
end;

function Th3Api.uncompactCells(const compactedSet: Ph3Index; const numCompacted: Int64; outSet: Ph3Index; const numOut: Int64; const res: Integer): Th3Error;
begin
  CheckMethod(@@FuncompactCells);
  Result:= FuncompactCells(compactedSet,numCompacted,outSet,numOut,res);
end;

function Th3Api.uncompactCellsSize(const compactedSet: Ph3Index; const numCompacted: Int64; const res: Integer; pRetVal: PInt64): Th3Error;
begin
  CheckMethod(@@FuncompactCellsSize);
  Result:= FuncompactCellsSize(compactedSet,numCompacted,res,pRetVal);
end;

function Th3Api.vertexToLatLng(vertex: Th3Index; var lat,lng: double): Th3Error;
var point: Th3LatLng;
begin
  CheckMethod(@@FvertexToLatLng);
  Result:= FvertexToLatLng(vertex,@point);
  if Result = Th3Error(Th3ErrorCodes.E_SUCCESS) then
  begin
    lat := point.Latitude;
    lng := point.Longitude;
  end
  else
  begin
    lat := lat.NaN;
    lng := lat;
  end;
end;
{$endregion}

end.
