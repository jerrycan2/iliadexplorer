unit normalizer;
// Normalization for Basic Latin, Latin-1 supplement, Greek and Greek Extended (blocks 0000, 0300, 1F00)

interface

uses System.SysUtils, System.Character, FMX.Dialogs;

type
  tNormalForm = (nfNFC, nfNFD, nfNONE); //normalize to 1: NFC 2:NFD 3:remove all diacritics and capitalization
  tWordArray = TArray<word>;
  tWordArrayArray = TArray<tWordArray>;
type
  TNormalizer = class
  private
    FNonSpacingMarks: set of $00..$70;
    procedure ReadNonSpacingMarks;
    function LookupSourceChar(const AChar: word): integer; //rtns index in CHARSOURCE or -1
    function LookupNFC(const AChar: word): integer; //rtns index in CHARNFC or -1
    function LookupNFD(const Chars: tWordArray): integer; //rtns index in CHARNFD or -1
// FSourceChar: character in question    FNfcChar: its canonical form, composed    FNfdChar: canonical form, decomposed
// If sourcechar is not in the 1st array, use it as is. Then it cannot have combining marks.
// all 3 arrays same length, indexes correspond.
// Any second, third etc. chars in FNfdChar are nonspacingmarks. All Greek nonspacingmarks are in the range $300-$36F
// NB codepoint $0344 (COMBINING GREEK DIALYTIKA TONOS) has NFC of 2 characters, replaced here by $0344
// data from the file 'NormalizationTest.txt' from the UCD at unicode.org
  const
{$INCLUDE 'unicode_tables_latingreek.txt'}      //tables declared as const
//      FSourceChar:  tWordArray = [];         //length 342
//      FNfcChar:     tWordArray = [];
//      FNfdChar: tWordArrayArray =  [[]];



  public
    constructor Create;
    function Normalize(const Text: string; const NormalForm: tNormalForm): string;
    function QuickNFCCheck(const text: string): boolean;
    function IsNonSpacing(c: word): boolean;
end;

implementation

constructor TNormalizer.Create;
begin
  inherited;
  ReadNonSpacingMarks;
end;

procedure TNormalizer.ReadNonSpacingMarks;
var
  I, J: integer;
begin
  for I := 0 to High(FNfdChar) do
    for J := 1 to High(FNfdChar[I]) do
      if (FNfdChar[I][J] >= $0300) and (FNfdChar[I][J] < $0370) then
         FNonSpacingMarks := FNonSpacingMarks + [FNfdChar[I][J] and $FF];
end;

//normalize: first decompose, set in canonical order, if NFC then compose
function TNormalizer.Normalize(const Text: string; const NormalForm: tNormalForm): string;
var
  I, NFDLength, TextIndex, ArrayIndex, BufferIndex: integer; //running index to Text etc;
  NSMCount, NFDindex: integer;    //count of non-spacing chars after a Starter
  ReadIndex, WriteIndex: integer; //indexes to Buffer. WriteIndex is always >= ReadIndex (because NFD >= NFC)
  First: word;
  Buffer, LookupBuf: tWordArray;
begin
  //decompose:
  SetLength(Buffer, 5 * Text.Length); //worst case
  SetLength(LookupBuf, 6);
  BufferIndex := 0;
  TextIndex := Low(Text);
  try
    while TextIndex <= High(Text) do
    begin
      if NormalForm <> nfNONE then First := Ord(Text[TextIndex]) //First must be a 'starter'
      else First := Ord(Text[TextIndex].ToLower);
      ArrayIndex := LookupSourceChar(First);
      //if ArrayIndex = -1 then
      begin
        LookupBuf[0] := First;
        NSMCount := 0;
        while IsNonSpacing(Ord(Text[TextIndex + NSMCount + 1])) do
        begin
          LookupBuf[NSMCount+1] := Ord(Text[TextIndex + NSMCount + 1]);
          inc(NSMCount);
          if NSMCount > 4 then raise Exception.Create('Unicode error: too many combining marks');
        end;
      end;
      if NSMCount > 0 then //has combining marks
      begin
        LookupBuf[NSMCount + 1] := 0;
        NFDindex := LookupNFD(LookupBuf)  //is it already decomposed?
      end
      else  //is nfc
        NFDindex := ArrayIndex;
      if NFDindex <> -1 then  //is decomposed, normalize it
      begin
        for I := 0 to Length(FNfdChar[NFDindex])-1 do
        begin
         Buffer[BufferIndex] := FNfdChar[NFDindex][I];
         inc(BufferIndex); //canonical order
        end;
      end
      else
      begin
        if NSMCount > 0 then
        begin
          ShowMessage('Unicode error: unknown combining characters');
        end;

        Buffer[BufferIndex] := First;
        inc(BufferIndex);
      end;
      inc(TextIndex, 1 + NSMCount);
    end;
    //now it's decomposed, in the buffer
    if NormalForm <> nfNFD then //compose
    begin
      ReadIndex := 0;
      WriteIndex := 0;
      while ReadIndex < BufferIndex do  //limit set in previous loop
      begin
        NFDLength := 1; // 1 + nr of combining chars
        LookupBuf[0] := Buffer[ReadIndex];

        while IsNonSpacing(Buffer[ReadIndex + NFDLength]) do
        begin
          LookupBuf[NFDLength] := Buffer[ReadIndex + NFDLength];
          inc(NFDLength);
        end;
        if NormalForm <> nfNONE then
        begin
          LookupBuf[NFDLength] := 0;
          ArrayIndex := LookupNFD(LookupBuf);
        end
        else ArrayIndex := -1;//skipping combiners
        if ArrayIndex <> -1 then
          Buffer[WriteIndex] := FNfcChar[ArrayIndex]
        else
          Buffer[WriteIndex] := LookupBuf[0];

        inc(WriteIndex);
        inc(ReadIndex, NFDLength);
      end;
    end
    else WriteIndex := BufferIndex;

  except
    On E : Exception do
    begin
      ShowMessage(E.Message);
      exit;
    end;
  end;

  SetString(Result, PChar(@(Buffer[0])), WriteIndex);
end;

function TNormalizer.IsNonSpacing(c: word): boolean;
begin
  Result := (c - $300) in FNonSpacingMarks;  // 0 <= (c-$300) <= $FF
end;

function TNormalizer.QuickNFCCheck(const Text: string): boolean;
var //return true iff Text is NFC
  I, ArrayIndex: integer;
  CharValue : word;
begin
  Result := True;
  for I := Low(Text) to High(Text) do
  begin
    CharValue := Ord(Text[I]);
    ArrayIndex := LookupSourceChar(CharValue);
    if IsNonSpacing(CharValue) or
      ((ArrayIndex <> -1) and (FNfcChar[ArrayIndex] <> CharValue)) then
    begin
      Result := False;
      break;   //rtn false if at least one char is not NFC
    end;
  end;
end;

function TNormalizer.LookupSourceChar(const AChar: word): integer;
var
  I: integer;
begin
  Result := -1;
  for I := 0 to High(FSourceChar) do
  begin
    if FSourceChar[I] >= AChar then // they are sorted
    begin
      if FSourceChar[I] = AChar then Result := I;
    end;
    break;
  end;
end; // returns index or -1;

function TNormalizer.LookupNFC(const AChar: word): integer;
var
  I: integer;
begin
  Result := -1;
  for I := 0 to High(FNfcChar) do
  begin
    if FNfcChar[I] = AChar then // they are not sorted
    begin
      Result := I;
      break;
    end;
  end;
end; // returns index or -1;

function TNormalizer.LookupNFD(const Chars: tWordArray): integer; //rtns index in CHARNFD or -1
var
  I, J, K: integer;
  CharValue: word;
  Found: boolean;
begin //in Chars: base char always first, order of combining chars can vary
  Result := -1;
  Found := False;
  for I := 0 to High(FNfdChar) do
  begin
    if Chars[0] = FNfdChar[I][0] then
    begin
      J := 1;
      while Chars[J] <> 0 do
      begin
        CharValue := Chars[J];
        if CharValue = 0 then break;

        Found := False;
        for K := 1 to High(FNfdChar[I]) do
        begin
          if CharValue = FNfdChar[I][K] then
          begin
            Found := True;
            break;   //break K-loop   (1 of Chars[] found)
          end;
        end;
        if not Found then break;   //break J-loop  : not all of them found
        J := J + 1; // next char in buffer
      end;
      if J < Length(FNfdChar[I]) then Found := False; //shorter one in Chars[]

      if Found then  //all of Chars[] found
      begin
        Result := I;
        break;
      end;
    end;
  end;
end;


end.
