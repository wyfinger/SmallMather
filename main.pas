unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
    Math;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    edtExpression: TEdit;
    mmoCalcLog: TMemo;
    procedure edtExpressionChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
    CalcLog: TStringList;
  public
    { public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

function Calc(Expr: string; CalcLog: TStrings = nil): string;
  function GetNextNum(Expr: string; var Remain: string): string;
  var
    i: Integer;
    Started: Boolean;
  begin
    Started := False;
    Result := '';
    Remain := '';
    for i := 1 to Length(Expr) do
      if (Expr[i] in ['0'..'9', '.']) or ((Expr[i] = '-') and (i = 1)) then
        begin
          Started := True;
          Result := Result + Expr[i];
        end
      else
        if Started then
          begin
            Remain := Copy(Expr, i, Length(Expr)-i+1);
            Break;
          end;
  end;
  function GetNextWord(Expr: string; var Remain: string): string;
  var
    i: Integer;
    Started: Boolean;
  begin
    Started := False;
    Result := '';
    Remain := '';
    for i := 1 to Length(Expr) do
      if (not (Expr[i] in ['0'..'9', '.', '-'])) or ((Expr[i] = '-') and (i = 1)) then
        begin
          Started := True;
          Result := Result + Expr[i];
        end
      else
        if Started then
          begin
            Remain := Copy(Expr, i, Length(Expr)-i+1);
            Break;
          end;
  end;
  function CalcOperations(Expr: string): string;
  var
    Item: string;
    Flag: Boolean;
    ExprArray: array of string;
    i: Integer;
    procedure CalcOperation(ExprNo: Integer);
    var
      i: Integer;
      Result: string;
    begin
      case ExprArray[ExprNo] of
        '+' : Result := FloatToStr(StrToFloat(ExprArray[ExprNo-1]) + StrToFloat(ExprArray[ExprNo+1]));
        '-' : Result := FloatToStr(StrToFloat(ExprArray[ExprNo-1]) - StrToFloat(ExprArray[ExprNo+1]));
        '*' : Result := FloatToStr(StrToFloat(ExprArray[ExprNo-1]) * StrToFloat(ExprArray[ExprNo+1]));
        '/' : Result := FloatToStr(StrToFloat(ExprArray[ExprNo-1]) / StrToFloat(ExprArray[ExprNo+1]));
        '%' : Result := IntToStr(StrToInt(ExprArray[ExprNo-1]) mod StrToInt(ExprArray[ExprNo+1]));
        else Result := ExprArray[ExprNo];
      end;
      for i := ExprNo to Length(ExprArray)-2 do
        ExprArray[i] := ExprArray[i+1];
      for i := ExprNo to Length(ExprArray)-2 do
        ExprArray[i] := ExprArray[i+1];
      ExprArray[ExprNo-1] := Result;
      ExprArray[Length(ExprArray)-1] := '';
      ExprArray[Length(ExprArray)-2] := '';
      SetLength(ExprArray, Length(ExprArray)-2);
    end;
  begin
    Item := GetNextNum(Expr, Expr);
    SetLength(ExprArray, 1);
    ExprArray[0] := Item;
    Flag := False;
    while True do
      begin
        if Flag then
          Item := GetNextNum(Expr, Expr)
        else
          Item := GetNextWord(Expr, Expr);
        Flag := not Flag;
        if Length(Item) = 0 then Break;
        SetLength(ExprArray, Length(ExprArray)+1);
        ExprArray[Length(ExprArray)-1] := Item;
      end;
    if Length(ExprArray) = 1 then
      begin
        Result := ExprArray[0];
        Exit;
      end;
    Flag := True;
    while Flag do
      begin
        Flag := False;
        for i := 0 to Length(ExprArray)-1 do
          case ExprArray[i] of
            '*','/','%': begin
                           CalcOperation(i);
                           Flag := True;
                           Break;
                         end;
          end;
      end;
    Flag := True;
    while Flag do
      begin
        Flag := False;
        for i := 0 to Length(ExprArray)-1 do
          case ExprArray[i] of
            '+','-': begin
                       CalcOperation(i);
                       Flag := True;
                       Break;
                     end;
          end;
      end;
    Result := ExprArray[0];
  end;
  function CalcFunction(Expr: string; var ClearExpr: string): string;
  var
    i: Integer;
    Remain, FuncName: string;
    Parameter: string;
    Params: array of string;
  begin
    FuncName := GetNextWord(Expr, Remain);
    FuncName := Copy(FuncName, 1, Length(FuncName)-1);
    Parameter := '';
    for i := 1 to Length(Remain)-1 do
      if Remain[i] <> ',' then
        Parameter := Parameter + Remain[i]
      else
        begin
          SetLength(Params, Length(Params)+1);
          Params[Length(Params)-1] := CalcOperations(Parameter);
          Parameter := '';
        end;
    SetLength(Params, Length(Params)+1);
    Params[Length(Params)-1] := CalcOperations(Parameter);
    ClearExpr := FuncName + '(';
    for i := 0 to Length(Params)-1 do
      if i = Length(Params)-1 then
        ClearExpr := ClearExpr + Params[i] + ')'
      else
        ClearExpr := ClearExpr + Params[i] + ',';
    case AnsiLowerCase(FuncName) of
      'sin' : Result := FloatToStr(sin(StrToFloat(Params[0])));
      'cos' : Result := FloatToStr(cos(StrToFloat(Params[0])));
      'min' : Result := FloatToStr(Math.Min(StrToFloat(Params[0]),StrToFloat(Params[1])));
      'max' : Result := FloatToStr(Math.Min(StrToFloat(Params[0]),StrToFloat(Params[1])));
      'abs' : Result := FloatToStr(abs(StrToFloat(Params[0])));
      'sqr' : Result := FloatToStr(sqr(StrToFloat(Params[0])));
      'sqrt' : Result := FloatToStr(sqrt(StrToFloat(Params[0])));
      'round' : if Length(Params) = 1 then
                  Result := FloatToStr(round(StrToFloat(Params[0])))
                else
                  Result := FloatToStr(round(StrToFloat(Params[0])*Power(10,StrToInt(Params[1])))/Power(10,StrToInt(Params[1])));
      'frac' : Result := FloatToStr( frac(StrToFloat(Params[0])));
      'trunc' : Result := IntToStr( floor(StrToFloat(Params[0])) );
      'ceil' : Result := IntToStr( ceil(StrToFloat(Params[0])) );
      else Result := Expr;
    end;
  end;
  procedure AddLog(LogStr: string);
  begin
    LogStr := Trim(LogStr);
    LogStr := StringReplace(LogStr, '+-', '-', [rfReplaceAll]);
    LogStr := StringReplace(LogStr, '--', '+', [rfReplaceAll]);
    if (CalcLog <> nil) and
       ((CalcLog.Count = 0) or (LogStr <> CalcLog[CalcLog.Count-1]))
         then CalcLog.Add(LogStr);
  end;
var
  i: Integer;
  BracDepth, BracDepthMax, BracDepthMaxPrev: Integer;
  PieceStart, PieceEnd: Integer;
  IsFunction: Boolean;
  SubResult: string;
  WorkStr, ClearExpr: string;
  TestFloat: Double;
begin
  WorkStr := Expr;
  BracDepthMaxPrev := 0;
  while True do
    begin
      PieceStart := 0;
      PieceEnd := Length(WorkStr);
      IsFunction := False;
      BracDepth := 0;
      BracDepthMax := 0;
      for i := 1 to Length(WorkStr) do
        begin
          if WorkStr[i] = '(' then
            begin
              Inc(BracDepth);
              if BracDepth > BracDepthMax then
                begin
                  PieceStart := i;
                  BracDepthMax := BracDepth;
                end;
            end;
          if WorkStr[i] = ')' then
            begin
              Dec(BracDepth);
              if (BracDepth = BracDepthMax-1) and (PieceEnd = Length(WorkStr)) then
                PieceEnd := i;
            end;
        end;
      if BracDepth <> 0 then raise Exception.Create('Brackets error');
      if (CalcLog <> nil) and (BracDepthMax < BracDepthMaxPrev) then
        AddLog(WorkStr);
      BracDepthMaxPrev := BracDepthMax;
      IsFunction := False;
      if PieceStart > 0 then
        for i := PieceStart-1 downto 1 do
          if WorkStr[i] in ['a'..'z','A'..'Z'] then
            begin
              PieceStart := i;
              IsFunction := True;
            end
          else
            Break;
      SubResult := Copy(WorkStr, PieceStart, PieceEnd - PieceStart + 1);
      if IsFunction then
        begin
          SubResult := CalcFunction(SubResult, ClearExpr);
          AddLog(Copy(WorkStr, 1, PieceStart - 1) + ClearExpr + Copy(WorkStr, PieceEnd + 1, Length(WorkStr) - PieceEnd + 1));
        end
      else
        SubResult := CalcOperations(SubResult);
      SubResult := Copy(WorkStr, 1, PieceStart - 1) + SubResult + Copy(WorkStr, PieceEnd + 1, Length(WorkStr) - PieceEnd + 1);
      if SubResult = WorkStr then
        Break
      else
        WorkStr := SubResult;
    end;
  if not TryStrToFloat(WorkStr, TestFloat) then
    raise Exception.Create('Bad expression');
  AddLog(WorkStr);
  Result := WorkStr;
end;

{ TfrmMain }

procedure TfrmMain.edtExpressionChange(Sender: TObject);
var
  Expr : string;
begin
  try
    CalcLog.Clear;
    Expr := Trim(StringReplace(edtExpression.Text, ' ', '', [rfReplaceAll]));
    if Length(Expr) = 0 then raise Exception.Create('Empty expression');
    Calc(Expr, CalcLog);
    mmoCalcLog.Text := CalcLog.Text;
    edtExpression.Color := clWindow;
  except
    edtExpression.Color := $00D5D5FF;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  CalcLog := TStringList.Create;
end;

end.

