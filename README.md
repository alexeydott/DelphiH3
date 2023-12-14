# DelphiH3
Delphi bindings for UBER H3 library

### simple usage:

```
//... uses h3Lib.Api;

procedure h3ApiTest;
var
  h3DllPath: string;
  h1,h2: UInt64;
  lat,lng: Double;
  b: TArray<Th3LatLng>;
  p: Th3LatLng;
  Fh3api: Ih3API;// api singleton
begin
  // api library full path eq
  h3DllPath := ExpandFileName('..\..\'+h3Lib.Api.h3dllDefname);
  // you can also set it in the environment variable:
  // SetEnvironmentVariable(H3_DLL_PATH,PChar(h3DllPath));
  // h3DllPath := '';
  Fh3api := Th3Api.Create(h3DllPath);
  h1 := 621807530998366207;
  // index > lat,lng
  Fh3api.CellToLatLng(h1,lat,lng);
  // lat,lng to index
  Fh3api.LatLngToCell(lat,lng,10,h2);
  Assert(h1 - h2 = 0);
  // cell boundary in lat,lng
  if Fh3api.CellToBoundary(h2,b) then
  for p in b do
    WriteLn(Format('%8.3f,%8.3f',[p.Latitude,p.Longitude]));
end;
```
