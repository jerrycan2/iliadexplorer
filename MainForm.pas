unit MainForm;

interface

uses
    System.SysUtils, System.Types, System.Math, System.UITypes, System.Classes, System.Variants, System.IOUtils,
    Xml.xmldom, Xml.XMLIntf, Xml.XMLDoc, Xml.adomxmldom,
    FMX.Types, FMX.Platform, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
    FMX.StdCtrls,
    FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.TabControl, System.Actions,
    FMX.ActnList, FMX.ListView, FMX.TextLayout, FMX.Layouts, System.ImageList, FMX.ImgList;

{$REGION 'Type declarations'}

type
    TListProps = record
        ItemHeight, TextHeight, DetailHeight, DetailWidth, EditGlyphOffset, ImageSize, TextOffset, EditModeOffset: word;
    end;

type
    TTreeItemData = record // TListView 'lvTree' item data
        tr_itemLevel: integer; // from xml localname
        tr_itemListindex: integer; // points to item in lv_Tree
        tr_itemBGcolor: TAlphaColor;
        tr_itemFGcolor: TAlphaColor;
        tr_itemText: string;
        tr_itemDetail: string;
        tr_itemItalic: boolean;
        tr_itemExpanded: boolean;
        tr_itemVisible: boolean;
        tr_itemHasChildren: boolean;
    end;

type
    TMyListItemText = class(TListItemText)
    private
        FOffset: Single;
        FBGColor, FTextColor: TAlphaColor;
        FMyRect: TRectF;
        FXRadius: integer;
        FYRadius: integer;
    protected
        procedure CalculateLocalRect(const DestRect: TRectF; const SceneScale: Single;
            const DrawStates: TListItemDrawStates; const Item: TListItem); override;
        procedure Render(const Canvas: TCanvas; const DrawItemIndex: integer; const DrawStates: TListItemDrawStates;
            const Resources: TListItemStyleResources; const Params: TListItemDrawable.TParams;
            const SubPassNo: integer = 0); override;
    public
        constructor create(const AOwner: TListItem); override;
        destructor destroy; override;
    end;

type
    TForm1 = class(TForm)
        TopToolBar: TToolBar;
        TabControl1: TTabControl;
        StatusBar1: TStatusBar;
        KBPanel: TPanel;
        HomeTab: TTabItem;
        StructTab: TTabItem;
        GreekTab: TTabItem;
        EngTab: TTabItem;
        ScrollBox: THorzScrollBox;
        lvGreek: TListView;
        lvButler: TListView;
        SpeedBtnRight: TSpeedButton;
        SpeedBtnLeft: TSpeedButton;
        ActionList1: TActionList;
        NextTabAction1: TNextTabAction;
        PreviousTabAction1: TPreviousTabAction;
        StyleBook1: TStyleBook;
        ImageList1: TImageList;
        SpeedButton1: TSpeedButton;
        SpeedButton2: TSpeedButton;
        lvTree: TListView;
        procedure FormResize(Sender: TObject);
        procedure FormCreate(Sender: TObject);
        procedure FormDestroy(Sender: TObject);
        procedure TopToolBarClick(Sender: TObject);
        procedure lvClickBookmark(Sender: TObject);
        procedure Collapse1ButtonClick(Sender: TObject);
        procedure Expand1ButtonClick(Sender: TObject);
        procedure lvTreeItemClickEx(const Sender: TObject; ItemIndex: integer; const LocalClickPos: TPointF;
            const ItemObject: TListItemDrawable);
        procedure lvTreeUpdateObjects(const Sender: TObject; const AItem: TListViewItem);
        procedure lvItemResize(Sender: TObject);
        procedure StartGreekUpdateActions(Sender: TObject);
        procedure StartButlerUpdateActions(Sender: TObject);
        procedure StartTreeUpdateActions(Sender: TObject);
        procedure EndUpdateActions(const Sender: TObject);
        procedure lvUpdateObjects(const Sender: TObject; const AItem: TListViewItem);
    procedure GreekTabClick(Sender: TObject);
    procedure EngTabClick(Sender: TObject);

    private
        FXMLDocument: IXMLDocument;
        FTreeItemData: array of TTreeItemData; // linked to lvTree
        FIsPortrait: boolean;
        lvDisplayLevel: integer;
        lvListViewProps: TListProps;
        lvLineHeight: Single;
        lvFontsize: Single;
        lvTextLayout: TTextLayout;
        lvCommonFont: TFont;
        lvMaxWidth: Single;
        lvItemRect: TRectF;
        lvBrush: TBrush;
        lvBookmark: TBitmap;
        lvItemTextWidth: Single;
        lvListWidthGlobal: Single;
        FPath: string;

        procedure FillListProps;
        procedure ListViewSetProps(ListView: TListView; const ListViewProps: TListProps);

    public
        function GetTextHeight(const D: TListItemText; const Width: Single; const Text: string): integer;
        procedure SetTextHeight;
        function lvFillList(target: TListView; filename: TFileName): integer;
        procedure XML2Tree(ListView: TListView; XMLDoc: IXMLDocument);
        procedure ResetTree;
        procedure DrawTree;
        function MakeHeaderTitle(const targetname: string): string;

    const
        clvDetailWidth     = 48; // = also textoffset for lvButler, lvGreek
        clvGlyphWidth      = 20;
        clvMoreWidth       = 24;
        clvTextOffset      = 24;
        clvEditImageOffset = clvGlyphWidth;
        clvEditTextOffset  = clvTextOffset; // minimumtextoffset for lvTree
        clvMoreOffset      = 0;
        clvRightMargin     = 16;
        clvDefaultFG       = TAlphaColorRec.Darkgreen;
        clvDefaultBG       = TAlphaColorRec.Wheat;
        clvLevelOffset     = 16;

    end;

{$ENDREGION}

var
    Form1: TForm1;
    GrTitleBuf: packed array [0 .. 8] of char = (
        'Ι',
        'Λ',
        'Ι',
        'Α',
        'Δ',
        'Ο',
        'Σ',
        ' ',
        ' '
    );
    EngTitleBuf: packed array [0 .. 7] of char = (
        'I',
        'L',
        'I',
        'A',
        'D',
        ' ',
        ' ',
        '0'
    );

const
    IE_STANDARDHEIGHT = 48;
    GRALFABET: string = ('ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρστυφχψω');
    LALFABET: string  = ('ABGDEZHQIKLMNCOPRSTUFXYWabgdezhqiklmncoprstufxyw');
    COMMONFONTSIZE    = 13;
    RIGHTMARGIN       = 24;
    MINIMUMLVWIDTH    = 300;
    LEFTTEXTMARGIN    = 4;
    RIGHTTEXTMARGIN   = 4;
{$IFDEF MSWINDOWS}
    DEVICE_DEPENDENT_OFFSET = 2;
    STRINGSTART             = 1; // for 1-based strings indexing
    WINDOWSSCROLLBARSPACE   = 24;
{$ELSE}
    DEVICE_DEPENDENT_OFFSET = 2;
    STRINGSTART             = 0;
    WINDOWSSCROLLBARSPACE   = 0;
{$ENDIF}

implementation

{$R *.fmx}
{$R *.NmXhdpiPh.fmx ANDROID}
{$R *.Windows.fmx MSWINDOWS}
{$REGION 'MyListItemText'}

constructor TMyListItemText.create(const AOwner: TListItem);
begin
    inherited create(AOwner);
    WordWrap := true;
    TextAlign := TTextAlign.Leading;
    TextVertAlign := TTextAlign.Center;
end;

destructor TMyListItemText.destroy;
begin
    inherited;
end;

procedure TMyListItemText.CalculateLocalRect(const DestRect: TRectF; const SceneScale: Single;
    const DrawStates: TListItemDrawStates; const Item: TListItem);
begin
    inherited;
    FMyRect := DestRect;
end;

procedure TMyListItemText.Render(const Canvas: TCanvas; const DrawItemIndex: integer;
    const DrawStates: TListItemDrawStates; const Resources: TListItemStyleResources;
    const Params: TListItemDrawable.TParams; const SubPassNo: integer = 0);
var
    Item: TListViewItem;
    Drawable: TMyListItemText;
    rect: TRectF;
begin
    // no inherited; !
    rect := FMyRect; // set by CalculateLocalRect
    rect.Offset(Form1.clvTextOffset + FOffset, 0);

    Drawable := Self;
    Canvas.Font.Size := Drawable.Font.Size;
    rect.Width := Drawable.Width;
    rect.Height := Drawable.Height;
    Form1.lvBrush.Color := FBGColor;
    Canvas.FillRect(rect, Self.FXRadius, Self.FYRadius, [TCorner.BottomLeft], 1, Form1.lvBrush, TCornerType.Bevel);
    rect.Width := rect.Width - (LEFTTEXTMARGIN + RIGHTTEXTMARGIN);
    rect.Offset(LEFTTEXTMARGIN, 0);
    Canvas.Fill.Color := Self.FTextColor;
    Canvas.FillText(rect, Self.Text, Self.WordWrap, 1, [], Self.TextAlign, Self.TextVertAlign);
end;

{$ENDREGION}
{$REGION 'Form1 create resize destroy'}

procedure TForm1.FormCreate(Sender: TObject);
var
    ScreenService: IFMXScreenService;
    OrientSet: TScreenOrientations;
    Thread1, Thread2, Thread3: TThread;
begin
    // System.ReportMemoryLeaksOnShutdown := true;
    FPath := System.IOUtils.TPath.GetDocumentsPath + PathDelim;

    if (Max(Screen.Size.Width, Screen.Size.Height) < 3 * MINIMUMLVWIDTH) then
    begin
        if TPlatformServices.Current.SupportsPlatformService(IFMXScreenService, IInterface(ScreenService)) = true then
        begin
            OrientSet := [TScreenOrientation.soPortrait];
            ScreenService.SetScreenOrientation(OrientSet);
            FIsPortrait := true;
        end;
    end;

    // if (not FIsPortrait) and (Form1.ClientWidth > Form1.ClientHeight) then FIsPortrait := false
    // else FIsPortrait := true;

    lvBookmark := TBitmap.create;
    lvBookmark.LoadFromFile(FPath + 'bookmark.png');
    lvCommonFont := TFont.create;
    lvFontsize := 12;
    lvCommonFont.SetSettings('Lucida Sans Unicode', lvFontsize, TFontStyleExt.create([]));
    lvBrush := TBrush.create(TBrushKind.Solid, TAlphaColorRec.Darkkhaki);
    lvMaxWidth := lvGreek.Width;
    SetTextHeight; // sets lvLineHeight
    FXMLDocument := LoadXMLDocument(FPath + 'list.xml');
    FillListProps; // lvLineHeight must be set
    ListViewSetProps(lvTree, lvListViewProps); // todo
    ListViewSetProps(lvGreek, lvListViewProps);
    ListViewSetProps(lvButler, lvListViewProps);

    Thread1 := TThread.CreateAnonymousThread(
        procedure()
        begin
            lvFillList(lvGreek, FPath + 'gr_il2.dat');
        end);
    Thread1.OnTerminate := StartGreekUpdateActions;
    Thread1.Start;
    Thread2 := TThread.CreateAnonymousThread(
        procedure()
        begin
            lvFillList(lvButler, FPath + 'but_il2.dat');
        end);
    Thread2.OnTerminate := StartButlerUpdateActions;
    Thread2.Start;
    Thread3 := TThread.CreateAnonymousThread(
        procedure()
        begin
            lvDisplayLevel := 1;
            XML2Tree(lvTree, FXMLDocument);
            ResetTree;
        end);
    Thread3.OnTerminate := StartTreeUpdateActions;
    Thread3.Start;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
    lvCommonFont.Free;
    lvTextLayout.Free;
    lvBrush.Free;
    lvBookmark.Free;
end;

procedure TForm1.FormResize(Sender: TObject);
var
    tab3, tab4: TTabItem;
begin
    if not FIsPortrait then
    begin
        if (Form1.ClientWidth > Form1.ClientHeight) then // do landscape(only if 3 columns wide)
        begin // change to landscape
            FIsPortrait := false;
            lvGreek.Parent := ScrollBox; // move tabs 3 & 4 to tab 2
            lvButler.Parent := ScrollBox;
            TabControl1.TabIndex := 1;
            TabControl1.Tabs[3].Visible := false;
            TabControl1.Tabs[2].Visible := false;
            // resize landscape
            lvListWidthGlobal := Max(MINIMUMLVWIDTH, Form1.ClientWidth div 3);
            lvTree.Align := TAlignLayout.Left;
            StructTab.Width := 3 * lvListWidthGlobal;
            lvTree.Width := lvListWidthGlobal;
            lvGreek.Align := TAlignLayout.Left;
            lvGreek.Width := lvListWidthGlobal;
            lvGreek.Position.X := lvListWidthGlobal;
            lvButler.Align := TAlignLayout.Left;
            lvButler.Position.X := 2 * lvListWidthGlobal;
            lvButler.Width := lvListWidthGlobal;
        end else begin // portrait, create tab 3 & 4
            lvListWidthGlobal := Max(MINIMUMLVWIDTH, Form1.ClientWidth);
            TabControl1.Tabs[3].Visible := true;
            TabControl1.Tabs[2].Visible := true;
            lvGreek.Parent := TabControl1.Tabs[2];
            lvGreek.Align := TAlignLayout.Client;
            lvButler.Parent := TabControl1.Tabs[3];
            lvButler.Align := TAlignLayout.Client;
            lvTree.Align := TAlignLayout.Client;
        end;
    end;
    TopToolBar.Height := IE_STANDARDHEIGHT;
    StatusBar1.Height := IE_STANDARDHEIGHT;
    TabControl1.Height := Form1.ClientHeight - (TopToolBar.Height + StatusBar1.Height);
    // lvListWidthGlobal := Form1.ClientWidth;
    // FKBdown := true;
    //StartButlerUpdateActions(nil);
    //StartGreekUpdateActions(nil);
end;

procedure TForm1.lvItemResize(Sender: TObject);
begin // set width for lvTree, lvButler and lvGreek textobjects
    lvItemTextWidth := TListView(Sender).Width - TListView(Sender).ItemSpaces.Left - clvTextOffset - clvMoreWidth -
        WINDOWSSCROLLBARSPACE;
end;

procedure TForm1.StartGreekUpdateActions(Sender: TObject);
var
    n: integer;
begin
    // for n := 0 to lvGreek.Items.Count-1 do
    // begin
    // lvUpdateObjects(lvGreek, lvGreek.Items[n]);
    // end;
    lvGreek.OnUpdateObjects := lvUpdateObjects;
end;

procedure TForm1.StartButlerUpdateActions(Sender: TObject);
var
    n: integer;
begin
    // for n := 0 to lvButler.Items.Count-1 do
    // begin
    // lvUpdateObjects(lvButler, lvButler.Items[n]);
    // end;
    lvButler.OnUpdateObjects := lvUpdateObjects;
end;

procedure TForm1.StartTreeUpdateActions(Sender: TObject);
begin
    DrawTree;
    lvTree.OnUpdateObjects := lvTreeUpdateObjects;
end;

procedure TForm1.EndUpdateActions(const Sender: TObject);
begin
    TListView(Sender).OnUpdateObjects := nil;
end;

procedure TForm1.EngTabClick(Sender: TObject);
begin
    StartButlerUpdateActions(nil);
end;

function TForm1.GetTextHeight(const D: TListItemText; const Width: Single; const Text: string): integer;
begin
    lvTextLayout.BeginUpdate;
    try
        // lvTextLayout.MaxLayoutSize := TPointF.Create(lvItemTextWidth, 65535);
        // lvTextLayout.Font.Assign(D.Font);
        lvTextLayout.MaxSize := TPointF.create(Width, TTextLayout.MaxLayoutSize.Y);
        lvTextLayout.WordWrap := D.WordWrap;
        lvTextLayout.Text := Text;
    finally
        lvTextLayout.EndUpdate;
    end;
    // Get layout height
    Result := Floor(lvTextLayout.Height + 1);
end;

procedure TForm1.GreekTabClick(Sender: TObject);
begin
    StartGreekUpdateActions(nil);
end;

procedure TForm1.SetTextHeight; // get standard text height
begin
    // Create a TTextLayout to measure text dimensions
    lvTextLayout := TTextLayoutManager.DefaultTextLayout.create;
    lvTextLayout.BeginUpdate;
    try
        lvTextLayout.Font.Assign(lvCommonFont);
        lvTextLayout.VerticalAlign := TTextAlign.Center;
        lvTextLayout.HorizontalAlign := TTextAlign.Leading;
        lvTextLayout.WordWrap := true;
        lvTextLayout.Trimming := TTextTrimming.Word;
        lvTextLayout.MaxSize := TPointF.create(lvMaxWidth, TTextLayout.MaxLayoutSize.Y);
        lvTextLayout.Text := 'Ay';
    finally
        lvTextLayout.EndUpdate;
    end;
    // Get layout height
    lvLineHeight := Round(lvTextLayout.Height);
end;
{$ENDREGION}
{$REGION 'ListViews'}

procedure TForm1.TopToolBarClick(Sender: TObject);
begin
    //
end;

procedure TForm1.lvClickBookmark(Sender: TObject);
begin
    lvGreek.Items[lvGreek.ItemIndex].Objects.ImageObject.Visible := false;
end;

//procedure TForm1.lvUpdateObjects(const Sender: TObject; const AItem: TListViewItem);
//var
//    obj: TListItemDrawable;
//    Drawable, oldDrawable: TMyListItemText;
//    dindex: integer;
//    AvailableWidth: Single;
//    Text, s: string;
//begin
//    Drawable := TMyListItemText(AItem.View.FindDrawable('T'));
//    // if Drawable = nil then
//    begin
//        for dindex := 0 to AItem.View.Count - 1 do
//        begin
//            oldDrawable := TMyListItemText(AItem.View.Drawables[dindex]);
//            if (oldDrawable.Name = 'T') then // and (oldDrawable.TagFloat = 0) then
//            begin
//                Drawable := TMyListItemText.create(TListItem(oldDrawable.GetOwner));
//
//                Drawable.Name := 'T';
//                AItem.View.Delete(dindex);
//                AItem.View.Insert(0, Drawable);
//                break;
//            end;
//        end;
//    end;
//    if Drawable = nil then exit;
//
//    if AItem.Objects.ImageObject <> nil then AItem.Objects.ImageObject.Bitmap := lvBookmark;
//    Drawable.Text := AItem.Text;
//    Drawable.FOffset := clvDetailWidth - clvTextOffset;
//    lvItemResize(Sender);
//    Drawable.Width := lvItemTextWidth - Drawable.FOffset;
//    AItem.Height := GetTextHeight(Drawable, Drawable.Width - (LEFTTEXTMARGIN + RIGHTTEXTMARGIN), Drawable.Text);
//    // + Trunc(lvLineHeight);
//    if AItem.Purpose = TListItemPurpose.Header then
//    begin
//        Drawable.Font.Size := 18;
//        Drawable.FBGColor := TAlphaColorRec.Rosybrown;
//        Drawable.FTextColor := TAlphaColorRec.White;
//        AItem.Height := 2 * AItem.Height;
//    end else begin
//        Drawable.Font.Size := 12;
//        Drawable.FTextColor := TAlphaColorRec.Black;
//        if AItem.Index mod 2 = 0 then Drawable.FBGColor := TAlphaColorRec.Wheat
//        else Drawable.FBGColor := TAlphaColorRec.Tan;
//    end;
//    Drawable.Height := AItem.Height;
//    // log.d(TListView(Sender).Name + ':' + IntToStr(AItem.Index));
//    if AItem.Index = TListView(Sender).ItemCount - 1 then EndUpdateActions(Sender);
//
//end;

procedure TForm1.lvUpdateObjects(const Sender: TObject; const AItem: TListViewItem);
var
  Drawable: TListItemText;
  SizeImg: TListItemImage;
  Text: string;
  AvailableWidth: Single;
begin
  //SizeImg := TListItemImage(AItem.View.FindDrawable('imgSize'));
  AvailableWidth := TListView(Sender).Width - TListView(Sender).ItemSpaces.Left
    - TListView(Sender).ItemSpaces.Right;// - SizeImg.Width;

  // Find the text drawable which is used to calcualte item size.
  // For dynamic appearance, use item name.
  // For classic appearances use TListViewItem.TObjectNames.Text
  // Drawable := TListItemText(AItem.View.FindDrawable(TListViewItem.TObjectNames.Text));
  Drawable := TListItemText(AItem.View.FindDrawable('T'));
  // if Drawable = nil then Drawable := TListItemText(AItem.View.FindDrawable('txtMain'));

  Text := AItem.Text;
  Drawable.Text := Text;

  // Randomize the font when updating for the first time
//  if Drawable.TagFloat = 0 then
//  begin
//    Drawable.Font.Size := 1; // Ensure that default font sizes do not play against us
//    Drawable.Font.Size := 10 + Random(4) * 4;
//
//    Drawable.TagFloat := Drawable.Font.Size;
//    if Text.Length < 100 then
//      Drawable.Font.Style := [TFontStyle.fsBold];
//  end;
   Drawable.Font.Size := 16;
  // Calculate item height based on text in the drawable
  AItem.Height := GetTextHeight(Drawable, AvailableWidth, Text);
  Drawable.Height := AItem.Height;
  Drawable.Width := AvailableWidth;
  Drawable.TextColor := TAlphaColorRec.Black;
  //if AItem.Index mod 2 = 0 then Drawable.BGColor := TAlphaColorRec.Wheat

//  SizeImg.OwnsBitmap := False;
//  SizeImg.Bitmap := GetDimensionBitmap(SizeImg.Width, AItem.Height);
end;

function TForm1.MakeHeaderTitle(const targetname: string): string;
var
    BookL, BookH: char;
    i: integer;
begin
    if targetname = 'lvButler' then
    begin
        BookL := EngTitleBuf[7]; // global
        BookH := EngTitleBuf[6];
        BookL := Succ(BookL);
        if BookL > '9' then
        begin
            if BookH = ' ' then BookH := '1'
            else BookH := '2';
            BookL := '0';
        end;
        EngTitleBuf[7] := BookL;
        EngTitleBuf[6] := BookH;
        SetString(Result, PChar(@EngTitleBuf), Length(EngTitleBuf));
    end else begin

        i := GRALFABET.IndexOf(GrTitleBuf[8]);
        if i < 0 then // initially one not in the alfabet
                i := 0
        else i := i + 1;
        GrTitleBuf[8] := GRALFABET[STRINGSTART + i];
        SetString(Result, PChar(@GrTitleBuf), Length(GrTitleBuf));
    end;
end;

function TForm1.lvFillList(target: TListView; filename: TFileName): integer;
// fill lvGreek or lvButler
var
    ItemCount: integer;
    // count listviewitems for length of (global) ButlerHeights[]
    Item: TListViewItem;
    // items created and filled in here, sizes set by itemupdate()
    Stream: TFileStream; // *.dat file
    fieldsize: integer; // size of field (in bytes) in the above file
    FileBuffer: TBytes; // whole file at once
    bufferptr: integer; // byte index into FileBuffer
    streamsize: int64; // size of filebuffer
    intptr: ^integer;
    // holds address of FileBuffer[bufferptr] when it points to an integer
    itemtext, itemdetail: string; // read from FileBuffer
    Purpose: TListItemPurpose; // of the item under construction
begin
    ItemCount := 0;
    bufferptr := 0;

    Stream := TFileStream.create(filename, fmOpenRead);
    streamsize := Stream.Size;
    SetLength(FileBuffer, streamsize);
    Stream.ReadBuffer(FileBuffer, streamsize);
    FreeAndNil(Stream);
    target.Items.Clear;
    ItemCount := -1;
    while bufferptr < streamsize do
    begin
        Item := target.Items.Add;
        ItemCount := ItemCount + 1;
        // file format: [size of entry][entry] repeat until end
        // size = 4-byte integer), entry = string in UTF-16 format
        // size= -1: flag to indicate new 'book' (chapter)
        intptr := @(FileBuffer[bufferptr]);
        fieldsize := intptr^;
        bufferptr := bufferptr + 4; // file uses 4-byte fieldsize-integers
        if fieldsize = -1 then // Book header
        begin
            itemtext := MakeHeaderTitle(target.Name);
            itemdetail := '';
            Purpose := TListItemPurpose.Header;
        end
        else // normal item
        begin
            SetString(itemdetail, PChar(@(FileBuffer[bufferptr])), fieldsize div SizeOf(char));
            bufferptr := bufferptr + fieldsize;

            intptr := @(FileBuffer[bufferptr]);
            fieldsize := intptr^;
            bufferptr := bufferptr + 4;

            SetString(itemtext, PChar(@(FileBuffer[bufferptr])), fieldsize div SizeOf(char));
            bufferptr := bufferptr + fieldsize;

            Purpose := TListItemPurpose.None;
        end;

        Item.BeginUpdate;
        Item.Detail := itemdetail;
        Item.Text := itemtext;
        Item.Purpose := Purpose;
        Item.EndUpdate;
    end;
    Result := ItemCount;
end;

{$ENDREGION}
{$REGION 'Tree'}

procedure TForm1.XML2Tree(ListView: TListView; XMLDoc: IXMLDocument);
var
    jNode: IXMLNode;
    ItemIndex: integer;
    procedure ProcessNode(xmlnode: IXMLNode);
    var
        currxmlnode: IXMLNode;
        level: integer;
        s: string;
    begin // create: 1.item 2.children 3.siblings
        if (xmlnode = nil) or (xmlnode.LocalName = 'line') then exit;
        s := xmlnode.LocalName;
        level := StrToInt(s[low(s) + 3]); // level; s = 'lvl1' etc

        ItemIndex := ItemIndex + 1;
        SetLength(FTreeItemData, ItemIndex + 1);
        FTreeItemData[ItemIndex].tr_itemExpanded := false;
        FTreeItemData[ItemIndex].tr_itemLevel := level;
        if xmlnode.HasAttribute('ln') = true then FTreeItemData[ItemIndex].tr_itemDetail := xmlnode.Attributes['ln'];
        if xmlnode.HasAttribute('d') = true then FTreeItemData[ItemIndex].tr_itemText := xmlnode.Attributes['d'];
        // node screentext
        if xmlnode.HasAttribute('c') = true then
        begin
            FTreeItemData[ItemIndex].tr_itemBGcolor := StrToInt('$FF' + xmlnode.Attributes['c']);
        end
        else FTreeItemData[ItemIndex].tr_itemBGcolor := clvDefaultBG;
        // no color yet

        if xmlnode.HasAttribute('f') = true then
        begin
            FTreeItemData[ItemIndex].tr_itemFGcolor := StrToInt('$FF' + xmlnode.Attributes['f']);
            // foregroundcolor
        end
        else FTreeItemData[ItemIndex].tr_itemFGcolor := clvDefaultFG;

        if xmlnode.HasAttribute('ital') = true then
        begin
            FTreeItemData[ItemIndex].tr_itemItalic := true;
        end;
        // if xmlnode.HasChildNodes then tvnewnode.ImageIndex := 2
        // else tvnewnode.ImageIndex := 3;
        if xmlnode.HasChildNodes = true then // "leaf" node contains Greek text
        begin // not a leaf: must have children
            FTreeItemData[ItemIndex].tr_itemHasChildren := true;
            currxmlnode := xmlnode.ChildNodes.First;
            while currxmlnode <> nil do
            begin
                ProcessNode(currxmlnode);
                currxmlnode := currxmlnode.NextSibling;
            end;
        end;
    end; (* ProcessNode *)

begin (* XML2TREE *)
    if XMLDoc.ChildNodes.First = nil then
    begin
        ShowMessage('no XML!');
        exit;
    end;

    SetLength(FTreeItemData, 0);
    ItemIndex := -1; // static item counter
    jNode := XMLDoc.DocumentElement;
    ProcessNode(jNode);
end;

procedure TForm1.lvTreeUpdateObjects(const Sender: TObject; const AItem: TListViewItem);
var
    obj: TListItemDrawable;
    Index, n: integer;
    Offset: Single;
    AvailableWidth: Single;
    Drawable, oldDrawable: TMyListItemText;
begin
    Drawable := TMyListItemText(AItem.View.FindDrawable('mytext'));
    if Drawable = nil then
    begin
        for n := 0 to AItem.View.Count - 1 do
        begin
            oldDrawable := TMyListItemText(AItem.View.Drawables[n]);
            if (oldDrawable.Name = 'T') then
            begin
                Drawable := TMyListItemText.create(TListItem(oldDrawable.GetOwner));

                Drawable.Name := 'mytext';
                AItem.View.Delete(n);
                AItem.View.Insert(0, Drawable);
                break;
            end;
        end;
    end;
    if Drawable = nil then exit;

    if AItem.Objects.ImageObject <> nil then AItem.Objects.ImageObject.Bitmap := lvBookmark;
    index := AItem.Tag; // index to FTreeItemData
    AItem.Text := FTreeItemData[index].tr_itemText;
    Drawable.Font.Size := COMMONFONTSIZE;
    Drawable.FBGColor := FTreeItemData[index].tr_itemBGcolor;
    Drawable.FTextColor := FTreeItemData[index].tr_itemFGcolor;
    Drawable.TextVertAlign := TTextAlign.Leading;
    Drawable.FOffset := FTreeItemData[index].tr_itemLevel * clvLevelOffset;
    Drawable.Text := AItem.Text;
    lvItemResize(Sender);
    AItem.Height := GetTextHeight(Drawable, lvItemTextWidth - Drawable.FOffset, Drawable.Text) + Trunc(lvLineHeight);
    // tweak
    Drawable.Height := AItem.Height;
    AItem.Objects.DetailObject.Text := FTreeItemData[index].tr_itemDetail;
    AItem.Detail := FTreeItemData[index].tr_itemDetail;

    Drawable.Width := lvItemTextWidth - Drawable.FOffset;
    if FTreeItemData[index].tr_itemExpanded then
    begin
        Drawable.FXRadius := clvLevelOffset;
        Drawable.FYRadius := clvLevelOffset;
    end else if FTreeItemData[index].tr_itemHasChildren then
    begin
        Drawable.FXRadius := 8;
        Drawable.FYRadius := 8;
    end;
end;

procedure TForm1.ResetTree;
var
    listindex, level: integer;
begin
    lvTree.Items.Clear;
    for listindex := low(FTreeItemData) to high(FTreeItemData) do
    begin
        level := lvDisplayLevel - FTreeItemData[listindex].tr_itemLevel;
        if level >= 0 then
        begin
            FTreeItemData[listindex].tr_itemVisible := true;
            if (level > 0) and (FTreeItemData[listindex].tr_itemHasChildren) then
                    FTreeItemData[listindex].tr_itemExpanded := true
            else FTreeItemData[listindex].tr_itemExpanded := false;
        end else begin
            FTreeItemData[listindex].tr_itemVisible := false;
            FTreeItemData[listindex].tr_itemExpanded := false;
        end;
    end;
end;

procedure TForm1.DrawTree;
var
    listindex, treeindex, level: integer;
    Item: TListViewItem;
    obj: TMyListItemText;
begin
    for listindex := low(FTreeItemData) to high(FTreeItemData) do
    begin
        if FTreeItemData[listindex].tr_itemVisible = true then
        begin
            Item := lvTree.Items.Add;
            Item.Tag := listindex;
            // save listindex for reverse search (scrolling etc)
            FTreeItemData[listindex].tr_itemListindex := Item.Index;
            lvTreeUpdateObjects(lvTree, Item);
        end;
    end;

end;

procedure TForm1.Expand1ButtonClick(Sender: TObject);
begin
    if lvDisplayLevel < 6 then
    begin
        lvDisplayLevel := lvDisplayLevel + 1;
        // topitem := lvIndexFromPoint(lvTree, Trunc(lvTree.ScrollViewPos));
        ResetTree;
        DrawTree;
        // lvItemToTop(lvTree, topitem, true);
    end;
end;

procedure TForm1.Collapse1ButtonClick(Sender: TObject);
begin
    if lvDisplayLevel > 1 then
    begin
        lvDisplayLevel := (lvDisplayLevel - 1);
        ResetTree;
        DrawTree;
    end;
end;

procedure TForm1.lvTreeItemClickEx(const Sender: TObject; ItemIndex: integer; const LocalClickPos: TPointF;
const ItemObject: TListItemDrawable);
var
    obj: TMyListItemText;
    n, level0: integer;
    listindex: integer;

    procedure Expand(level: integer; showhide: boolean);
    begin // recursive expand/collapse using a common listindex
        listindex := listindex + 1;
        while FTreeItemData[listindex].tr_itemLevel > level do
        begin
            if listindex > high(FTreeItemData) then exit;
            if FTreeItemData[listindex].tr_itemLevel = level + 1 then
            begin
                FTreeItemData[listindex].tr_itemVisible := showhide;
                if (level < 7) and FTreeItemData[listindex].tr_itemExpanded then
                begin
                    Expand(level + 1, showhide);
                    continue;
                end;
            end;
            listindex := listindex + 1;
        end;
    end;

begin { lvTreeItemClickEx }
    if ItemObject <> nil then
    begin
        if ItemObject.Name = 'mytext' then
        begin
            obj := TMyListItemText(ItemObject);
            listindex := lvTree.Items[ItemIndex].Tag;
            if FTreeItemData[listindex].tr_itemHasChildren = false then exit;
            level0 := FTreeItemData[listindex].tr_itemLevel;
            n := listindex + 1;
            if FTreeItemData[listindex].tr_itemExpanded then
            begin
                FTreeItemData[listindex].tr_itemExpanded := false;
                Expand(level0, false); // false = collapse
            end else begin
                FTreeItemData[listindex].tr_itemExpanded := true;
                Expand(level0, true);
            end;
        end;
        lvTree.Items.Clear;
        DrawTree;
    end;
end;

{$ENDREGION}
{$REGION 'Format Listviews'}
// *********************************************************
// *****************FORMAT LISTS****************************
// *********************************************************

procedure TForm1.FillListProps; // todo: itemspace
begin
    with lvListViewProps do
    begin
        ItemHeight := 2 * Trunc(lvLineHeight) + 4;
        TextHeight := ItemHeight;
        DetailHeight := Trunc(lvLineHeight);
        DetailWidth := clvDetailWidth;
        ImageSize := 16;
        TextOffset := clvTextOffset;
        EditModeOffset := 0;

    end;
end;

procedure TForm1.ListViewSetProps(ListView: TListView; const ListViewProps: TListProps);

    procedure SetTextProperties(const AText: TTextObjectAppearance);
    begin
        AText.RestoreDefaults; // Restore to defaults for custom
        AText.Visible := false;       //from here
         AText.Height := 0; // don't set height here
         AText.VertAlign := TListItemAlign.Leading;
         AText.TextVertAlign := TTextAlign.Leading;
         AText.PlaceOffset.X := ListViewProps.TextOffset;
         AText.WordWrap := true;
         AText.Font := lvCommonFont;
         AText.Font.Size := lvFontsize;
    end;
    procedure SetDetailProperties(const ADetail: TTextObjectAppearance);
    begin
        ADetail.RestoreDefaults;
        ADetail.Height := ListViewProps.DetailHeight;
        ADetail.Width := ListViewProps.DetailWidth;
        ADetail.VertAlign := TListItemAlign.Leading;
        ADetail.TextVertAlign := TTextAlign.Leading;
        ADetail.PlaceOffset.X := 0;
        ADetail.PlaceOffset.Y := 0;
        ADetail.TextColor := TAlphaColorRec.Crimson;
        ADetail.Font := lvCommonFont;
        ADetail.Font.Size := lvFontsize;
        ADetail.Visible := true;
    end;
    procedure SetAccessoryProperties(const AAccessory: TAccessoryObjectAppearance);
    begin
        AAccessory.Align := TListItemAlign.Trailing;
        AAccessory.AccessoryType := TAccessoryType.More;
        AAccessory.PlaceOffset.X := clvMoreOffset;
        AAccessory.Width := clvMoreWidth;
        AAccessory.Visible := true;
    end;
// procedure SetEditAccessoryProperties(const AAccessory: TAccessoryObjectAppearance);
// begin
// AAccessory.Align := TListItemAlign.Trailing;
// AAccessory.AccessoryType := TAccessoryType.Checkmark;
// AAccessory.PlaceOffset.X := clvMoreOffset;
// AAccessory.Visible := true;
// end;
    procedure SetImageProperties(const AImage: TImageObjectAppearance);
    begin
        AImage.RestoreDefaults;
        AImage.Height := ListViewProps.ImageSize;
        AImage.Width := ListViewProps.ImageSize;
        AImage.VertAlign := TListItemAlign.Leading;
        AImage.Visible := true;
        AImage.PlaceOffset.Y := ListViewProps.DetailHeight;
        AImage.PlaceOffset.X := 0;
    end;
    procedure SetCommonProperties(const AObjects: TItemAppearanceObjects);
    begin
        SetTextProperties(AObjects.Text);
        SetDetailProperties(AObjects.Detail);
        SetImageProperties(AObjects.Image);
        SetAccessoryProperties(AObjects.Accessory);
    end;
    procedure SetEditItemProperties(const AObjects: TItemAppearanceObjects);
    begin
        AObjects.Image.Visible := false;
        AObjects.Detail.PlaceOffset.X := -16;
        AObjects.GlyphButton.Visible := true;
        AObjects.GlyphButton.ButtonType := TGlyphButtonType.Checkbox;
        AObjects.GlyphButton.VertAlign := TListItemAlign.Leading;
        AObjects.GlyphButton.Align := TListItemAlign.Leading;
        AObjects.GlyphButton.Height := ListViewProps.ImageSize;
        AObjects.GlyphButton.Width := ListViewProps.ImageSize;
        AObjects.GlyphButton.PlaceOffset.X := 1; // ListViewProps.EditGlyphOffset;
        AObjects.GlyphButton.PlaceOffset.Y := ListViewProps.DetailHeight;
        AObjects.Accessory.Visible := false;
        // SetEditAccessoryProperties(AObjects.Accessory);
    end;

var
    LObjects: TItemAppearanceObjects;
begin
    ListView.BeginUpdate;
    try
        ListView.ItemAppearance.ItemHeight := ListViewProps.ItemHeight;
        ListView.ItemAppearance.ItemEditHeight := ListViewProps.ItemHeight;
        // Set Item properties
        LObjects := ListView.ItemAppearanceObjects.ItemObjects;
        LObjects.BeginUpdate;
        try
            SetCommonProperties(LObjects);
        finally
            LObjects.EndUpdate;
        end;
        // Set Edit Item properties
        LObjects := ListView.ItemAppearanceObjects.ItemEditObjects;
        LObjects.BeginUpdate;
        try
            SetCommonProperties(LObjects);
            SetEditItemProperties(LObjects);
        finally
            LObjects.EndUpdate;
        end;
    finally
        ListView.EndUpdate;
    end;

end;
{$ENDREGION}
// Item := lvGreek.Items.Add;
// Item.Text :=
// 'Curabitur luctus ut enim et condimentum. Etiam vitae diam diam. Integer enim dolor, consectetur ut sodales vitae, dignissim vel lorem.';
// // Add.Data['txtMain']
// Item.Detail := 'detail1';
// Item := lvGreek.Items.Add;
// Item.Text := 'μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος' + sLineBreak + 'οὐλομένην, ἣ μυρί Ἀχαιοῖς ἄλγε ἔθηκε,' + sLineBreak
// + 'πολλὰς δ ἰφθίμους ψυχὰς Ἄϊδι προΐαψεν' + sLineBreak + 'ἡρώων, αὐτοὺς δὲ ἑλώρια τεῦχε κύνεσσιν' + sLineBreak +
// 'οἰωνοῖσί τε πᾶσι, Διὸς δ ἐτελείετο βουλή,' + sLineBreak + 'ἐξ οὗ δὴ τὰ πρῶτα διαστήτην ἐρίσαντε' + sLineBreak +
// 'Ἀτρεΐδης τε ἄναξ ἀνδρῶν καὶ δῖος Ἀχιλλεύς.';
// Item.Detail := 'detail3';
// Item := lvGreek.Items.Add;
// Item.Text := 'Dit is een gewone listview met wat extras.';
// Item.Detail := '24.234';

end.
