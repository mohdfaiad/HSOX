unit HSOXModule;

//      FIRST THINGS FIRST
//��������� ������ � TOR
//����������� ���������� ���� ������ ������� ����� ��� ��� ����� ������
//����� ������� ��� ����� ������
//����� ������� ��������� �������� ������ �� �����������������
//��������� ���������� ������ (Socks4-5,HTTPS,SSH)
//���������� ������������� ����� � ������������� ���������� ��� �������� ������
//�������������� ������ � google ��� ������ ������ � ������
//����������� ������ ������ (Classic, Dark, Light)
//�������� ����������� ������ ������
//����� ����� �� ������

interface

uses
    System.Classes, System.Variants, System.SysUtils,
    idHTTP, IdSSL, IdSSLOpenSSL, IdCookieManager,
    IdCustomTransparentProxy, IdSocks, IdTCPClient,
    SyncObjs, RegularExpressions, ceffmx, ceflib;

//���������� ��������� ��� ������
Const
  RE_GL2 = '(?ism-x)(<h3)(.*?)((http|https)(.*?)(?=&amp;))';
  RE_SS_DUCK = '(?ism-x)(<a class="result__url" rel="noopener" href=")(.*?)(?=")';
  RE_SS_DUCK2 = '(?ism-x)(http|https)(.*?)$';
  RE_GL5 = '(http|https)(.*)\w';
  RE_GL4 = '(?ism-x)(([0-9]{1,3}\.){3}([0-9]{1,3}))(.*?)((\d){2,5})';
  RE_GL_IP = '(?ism-x)(([0-9]{1,3}\.){3}([0-9]{1,3}))';
  RE_GL_PORT = '(?sim-x)[0-9]{2,5}$';
  RE_GL_INFO = '(?sim-x)"(.*?)"';

//�����������
Const
  TextL1 = '��������� ������ � ��������...';
  TextL2 = '�������� ������ ������ � ������...';
  TextL3 = '�������� ������...';
  TextL4 = '��������� ������ �� ������...';
  TextL5 = '������� ������ ������';
  TextL6 = '������ ���������� � ������ ������';


//������ ������ �� ������ � ����� ��������
Const google_search = 'https://www.google.com/search?q=free+socks5+proxy&start=';
      check_url1 = 'https://google.com';
      check_url2 = 'check2ip.com';
      check_url3 = 'https://ipinfo.io/';
      check_url4 = 'https://whoer.net';
      check_url5 = 'https://www.iplocation.net/';
      check_url6 = 'https://www.ip2location.com/';

//��� ���������� ���������
type TRegExp = record
  RegEx: TRegEx;
  Option: TRegExOptions;
  Pattern: String;
  RMath: TMatch;
  RMathes: TMatchCollection;
end;

//������ �� ������ Indy
type TParser = Class(TObject)
  var
    FHTTP: TIdHTTP;
    FSSL: TIdSSLIOHandlerSocketOpenSSL;
    FCookie: TIdCookieManager;
    RegExp: TRegExp;
  constructor Create;
  destructor Destroy; override;
  function AsHTML(Url: String): String;
end;

//��� ������
type TSocks = record
  ID: Integer;
  IP, PORT, STYPE, LOGIN, PASSW, STATUS, PAGE: String;
  LASTCHECK: TDateTime;
  Checking: Boolean;
  function InStrings: TStrings;
end;

//����� ���� � ������
type TLink = Class(TObject)
  public
    Url: String;
    CountSocks, PosSearch: Integer;
    Sockses: Array of TSocks;
    procedure SocksRandomize;
    procedure AddS(IP,PORT: String; STYPE: String=''; LOGIN: String=''; PASSW: String=''); overload;
    procedure AddS(Socks: TSocks); overload;
    procedure DelS; overload;
    constructor Create(Sender: TObject);
    Destructor Destroy; override;
End;

//���������� ������ � ������� ���������� ����
function UpDir(S: String; level: byte=1): String;
//��������� ����� ������ ������ � ������
procedure ParserLinks(Page : String);
//������ ������ ������ ������� �� �����
procedure ParserSocksInLinks(IndexLink: Word);
//������ ������ �������� ������� � �����
procedure CheckProxy(LinkIndex: Integer);
//��������� ��������� �� param.qtr
procedure LoadParam;
//��������� ��������� � param.qtr
procedure SaveParam;

Var
    Links: array[1..10] of TLink;//����� � ������
    n_google: Integer = 0;//����� �������� � ������
    IndexLink: Integer = 0;//����� �������� ����� � ������ � LinksWithSocks
    CountLinks: Integer = 0;//���-�� ������ � ������
    ParsedLinks, ParsingLinks, ParsedLink, FindingSocks, FindTorDir,
    ParsingLink, FindedSocks: Boolean;//���������� ���������� ��������� �������
    UrlInCheck, Inc_Word: String;
    Socks: TSocks;//������� �����

implementation
uses HSOXUnit;

//������ ������ ������ ������ � �����
procedure CheckProxy(LinkIndex: Integer);
begin
  FindingSocks :=True;
  //������� ����� �������� ������ � �����
  TThread.CreateAnonymousThread(procedure
        Var SocksInfo: TIdSocksInfo;
        Resp,Old_IP,S,dS: String;
        Live: Boolean;
        Count,i,j,IndexSocks: Integer;
        UrlInCheck: String;
        SParser: TParser;
        Socks: TSocks;
    begin
      //���� �� ������� ������ (�� ��������� 0) �� ����� ������ � ������
      For IndexSocks :=Links[LinkIndex].PosSearch to Length(Links[LinkIndex].Sockses)-1 do
      //���� ������� ������ �� ������
      if not FindedSocks then try
        //����������� �������
        Links[LinkIndex].PosSearch :=IndexSocks+1;
        SParser :=TParser.Create;
        Live :=False;
        Socks :=Links[LinkIndex].Sockses[IndexSocks];
        try
          WHSOX.LabelBottom.Text :='�������� ����������������� ������ '+Links[LinkIndex].Sockses[IndexSocks].IP
          +':'+Links[LinkIndex].Sockses[IndexSocks].PORT+' ...';
        except
        end;
        UrlInCheck :=check_url3+Links[LinkIndex].Sockses[IndexSocks].IP+'/json';
        Inc_Word :=Links[LinkIndex].Sockses[IndexSocks].IP;
        With SParser do
            try
              FHTTP.Disconnect;
              SocksInfo :=TIdSocksInfo.Create();
                With SocksInfo do
                  try
                    Enabled :=True;
                    Host :=Links[LinkIndex].Sockses[IndexSocks].IP;
                    Port :=StrToInt(Links[LinkIndex].Sockses[IndexSocks].PORT);
                    Authentication :=saNoAuthentication;
                  except
                  end;
              If Links[LinkIndex].Sockses[IndexSocks].STYPE='SOCKS5' then
                try
                  SocksInfo.Version :=svSocks5;
                  FSSL.TransparentProxy :=SocksInfo;
                  FHTTP.IOHandler :=FSSL;
                  Resp :=FHTTP.Get(UrlInCheck);
                  If Pos(inc_word,Resp)>0 then Live :=True;
                 except
                  Live :=False;
                 end else
              If Links[LinkIndex].Sockses[IndexSocks].STYPE='SOCKS4' then
                try
                  SocksInfo.Version :=svSocks4;
                  FSSL.TransparentProxy :=SocksInfo;
                  FHTTP.IOHandler :=FSSL;
                  Resp :=FHTTP.Get(UrlInCheck);
                  If Pos(Inc_Word,Resp)>0 then Live :=True;
                except
                  Live :=False;
                end else
              If Links[LinkIndex].Sockses[IndexSocks].STYPE='HTTPS' then
                try
                  FHTTP.IOHandler :=nil;
                  FHTTP.ProxyParams.ProxyServer :=Links[LinkIndex].Sockses[IndexSocks].IP;
                  FHTTP.ProxyParams.ProxyPort :=StrToInt(Links[LinkIndex].Sockses[IndexSocks].PORT);
                  Resp :=FHTTP.Get(UrlInCheck);
                  If Pos(Inc_Word,Resp)>0 then Live :=True;
                except
                  Live :=False;
                end else
              try
                SocksInfo.Version :=svSocks5;
                FSSL.TransparentProxy :=SocksInfo;
                FHTTP.IOHandler :=FSSL;
                Resp :=FHTTP.Get(UrlInCheck);
                If Pos(Inc_Word,Resp)>0 then
                  begin
                    Links[LinkIndex].Sockses[IndexSocks].STYPE :='SOCKS5';
                    Live :=True;
                  end;
              except
                try
                  SocksInfo.Version :=svSocks4;
                  FSSL.TransparentProxy :=SocksInfo;
                  FHTTP.IOHandler :=FSSL;
                  Resp :=FHTTP.Get(UrlInCheck);
                  If Pos(Inc_Word,Resp)>0 then
                    begin
                      Links[LinkIndex].Sockses[IndexSocks].STYPE :='SOCKS4';
                      Live :=True;
                    end;
                except
                  try
                    FHTTP.IOHandler :=nil;
                    FHTTP.ProxyParams.ProxyServer :=Links[LinkIndex].Sockses[IndexSocks].IP;
                    FHTTP.ProxyParams.ProxyPort :=StrToInt(Links[LinkIndex].Sockses[IndexSocks].PORT);
                    Resp :=FHTTP.Get(UrlInCheck);
                    If Pos(Inc_Word,Resp)>0 then
                      begin
                        Links[LinkIndex].Sockses[IndexSocks].STYPE :='HTTPS';
                        Live :=True;
                      end;
                  except
                    Live :=False;
                  end;
                end;
              end;
              SocksInfo.Free;
            except
            end;
        //����������� ���-�� ���������� ������ � ����� � ������
        try
          S :=WHSOX.LogBox.ItemByIndex(LinkIndex).ItemData.Detail;
          dS :=Copy(S,Pos('/',S)+1,Length(S)-Pos('/',S));
          S :=Copy(S,1,Pos('/',S)-1);
          i :=(StrToInt(S))+1;
          WHSOX.LogBox.ItemByIndex(LinkIndex).ItemData.Detail :=IntToStr(i)+'/'+dS;
        except
        end;
        If Live and (not FindedSocks) then
          begin
            begin
              Links[LinkIndex].Sockses[IndexSocks].STATUS :='LIVE';
              Links[LinkIndex].Sockses[IndexSocks].PAGE :=Resp;
              Sox :=Links[LinkIndex].Sockses[IndexSocks];
              FindedSocks :=True;
              try
                WHSOX.LabelBottom.Text :='������ ����� ����� '+Sox.IP+':'+Sox.PORT+' !';;
                WHSOX.LogBox.ItemByIndex(LinkIndex).IsSelected :=True;
              except
              end;
            end;
          end else
          begin
            Links[LinkIndex].Sockses[IndexSocks].STATUS :='DEAD';
          end;
        SParser.Free;
      except
      end else Break;
    end).Start;
end;

//������ ������ ������ ������� �� ������� �����
procedure ParserSocksInLinks(IndexLink: Word);
begin
  TThread.CreateAnonymousThread(procedure
    Var i,j: Word;
        R: TRegExp;
        Parser: TParser;
        dSocks: TSocks;
    begin
      Parser :=TParser.Create;
      With R do
        try
          RMathes :=RegEx.Matches(Parser.AsHTML(WHSOX.LogBox.Items[IndexLink]),RE_GL4);
          if RMathes.Count>0 then
            begin
              //����������� ���-�� ������� ������
              inc(CountLinks);
              Links[IndexLink].CountSocks :=RMathes.Count;
              j :=Round((RMathes.Count div 5)*5-1);
              //������ ����� � ������
              For i:=0 to j do
                begin
                  dSocks.IP :=RegEx.Match(RMathes[i].Value,RE_GL_IP).Value;
                  dSocks.PORT :=RegEx.Match(RMathes[i].Value,RE_GL_PORT).Value;
                  Links[IndexLink].AddS(dSocks.IP, dSocks.PORT);
                end;
              //������������ ��� ������ ��� ������������
              Links[IndexLink].SocksRandomize;
              Links[IndexLink].PosSearch :=0;
              //��������� ����� ������ ������ � �����
              CheckProxy(IndexLink);
              try
                WHSOX.LogBox.ItemByIndex(IndexLink).ItemData.Detail :='0/'+IntToStr(RMathes.Count);
              except
              end;
            end else try
              //�������� ����, ���� ������ �� �������
              WHSOX.LogBox.ItemByIndex(IndexLink).Visible :=False;
            except
            end;
            ParsedLink :=True;
            ParsingLinks :=False;
        except
        end;
      Parser.Free;
    end).Start;
end;

procedure StringVisitor(const str: ustring);
begin
  //str is the SourceHtml
  WHSOX.Memo1.Lines.Clear;
  WHSox.Memo1.Lines.Add(str)
end;

function GetSourceHTML: string;
var
CefStringVisitor:ICefStringVisitor;
begin
  CefStringVisitor := TCefFastStringVisitor.Create(StringVisitor);
  WHSox.ChromiumFMX1.Browser.MainFrame.GetSource(CefStringVisitor);
end;

//��������� ����� ������ ������ � ������
procedure ParserLinks(Page: String);
begin
  ParsingLinks :=True;
  TThread.CreateAnonymousThread(procedure
    Var i: Word;
        dS: String;
        R: TRegExp;
        SS: TStrings;
        Parser: TParser;
        CefStringVisitor:ICefStringVisitor;
    begin
      Parser :=TParser.Create;
      With R do
        try
//          WHSOX.ChromiumFMX1.Load('https://duckduckgo.com/?q=free+socks+5+proxy&t=h_&ia=web0');
//          While WHSOX.ChromiumFMX1.Browser.IsLoading do Sleep(250);
//          CefStringVisitor := TCefFastStringVisitor.Create(StringVisitor);
//          WHSOX.ChromiumFMX1.onl
//          WHSOX.ChromiumFMX1.Browser.MainFrame.GetSource(CefStringVisitor);
//          dS :=Parser.AsHTML('https://duckduckgo.com/?q=free+socks+5+proxy&t=h_&ia=web0');
//          SS :=TStringList.Create;
//          SS.Add(dS);
//          SS.SaveToFile('C:\Users\John\Documents\Embarcadero\Studio\Projects\qtor_m\Win32\Debug\test.txt');
//          SS.Free;
//          dS :=Parser.AsHTML('https://www.google.com/search?q=free+socks5+proxy&oq=free+socks5+proxy');
          case WHSOX.ComboBoxSearchSystems.ItemIndex of
            -1,0 :  begin
                      RMathes :=RegEx.Matches(Page,RE_SS_DUCK);
                      if RMathes.Count>0 then
                        begin
                          For i:=0 to RMathes.Count-1 do
                          begin
                            dS :=RMathes.Item[i].Value;
  //                          Links[i+1].Url :=RegEx.Match(dS, RE_SS_DUCK2).Value;
                            WHSOX.LogBox.Items.Add(RegEx.Match(dS, RE_SS_DUCK2).Value);
  //                          WHSOX.LogBox.ItemByIndex(WHSOX.LogBox.Items.Count-1).ItemData.Detail :='.../...';
                          end;
                          WHSOX.Memo1.Lines.Add('links parsed from duckduckgo.com');
                        end else WHSOX.Memo1.Lines.Add('links not parsed from duckduckgo.com');
            end;
          end;

//          WHSOX.LogBox.BeginUpdate;
//          WHSOX.LabelBottom.Text :=TextL3;
//          For i:=0 to RMathes.Count-1 do
//            begin
//              dS :=RMathes.Item[i].Value;
//              Links[i+1].Url :=RegEx.Match(dS,(RE_GL5)).Value;
//              WHSOX.LogBox.Items.Add(Links[i+1].Url);
//              WHSOX.LogBox.ItemByIndex(WHSOX.LogBox.Items.Count-1).ItemData.Detail :='.../...';
//            end;
//          WHSOX.LogBox.EndUpdate;
//          WHSOX.LogBox.UpdateEffects;
        except
        end;
//      inc(n_google);
      Parser.Free;
      ParsedLinks :=True;
      ParsingLinks :=False;
    end).Start;
end;

//��������� ��������� �� param.qtr
procedure LoadParam;
Var S: TStrings;
begin
  S :=TStringList.Create;
  if FileExists('param.qtr') then
    begin
      S.LoadFromFile('param.qtr');
      try
//        If FileExists(S[0]+TOR_exe) then
//          begin
//            TorDir :=S[0];
//            torrc :=TorDir+'TorBrowser\Data\Tor\torrc';
//            FindTorDir :=True;
//          end else FindTorDir :=False;
//        If S[1]='0' then WHSOX.AutoSeachProxy.Checked :=False;
//        If S[2]='0' then WHSOX.AutoInstallProxy.Checked :=False;
      except
        FindTorDir :=False;
      end;
    end;
end;

//��������� ��������� � param.qtr
procedure SaveParam;
Var S: TStrings;
begin
  S :=TStringList.Create;
//  S.Add(TorDir);
//  With WHSOX do
//    begin
//      if AutoSeachProxy.Checked then S.Add('1') else S.Add('0');
//      If AutoInstallProxy.Checked then S.Add('1') else S.Add('0');
//    end;
  S.SaveToFile('param.qtr');
end;

//���������� ������ � ������� ���������� ����
function UpDir(S: String; level: byte=1): String;
Var i,j: byte;
begin
  i :=Length(S);
  For j:=1 to level do
  try
    While S[i]<>'\' do
    try
      Delete(S,i,1);
      dec(i);
    except
    end;
    Delete(S,i,1);
  except
  end;
  Result :=S+'\';
end;


{ TParser }
constructor TParser.Create;
begin
  inherited;
  FSSL :=TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  FSSL.ConnectTimeout:=5000;
  FSSL.ReadTimeout:=5000;
  FHTTP :=TIdHTTP.Create(nil);
  FCookie := TIdCookieManager.Create(nil);
  FHTTP.CookieManager :=FCookie;
  FHTTP.IOHandler :=FSSL;
  FHTTP.HandleRedirects :=True;
  FHTTP.AllowCookies :=True;
  FHTTP.ReadTimeout:=5000;
  FHTTP.ConnectTimeout :=5000;
end;
destructor TParser.Destroy;
begin
  FCookie.Free;
  FHTTP.Free;
  FSSL.Free;
  inherited;
end;
//�������� ����� �� Url ������� � String
function TParser.AsHTML(Url: string): String;
begin
  try
  Result :=FHTTP.Get(Url);
  FHTTP.Disconnect;
  except
  end;
end;

{ TSocks }
//������������ ������ � ���� ������ ��� ������ � torrc
function TSocks.InStrings;
begin
  Result :=TStringList.Create;
  if STYPE = 'SOCKS4' then
    begin
      Result.Add('Socks4Proxy '+IP+':'+PORT);
    end else
  if STYPE = 'SOCKS5' then
    begin
      Result.Add('Socks5Proxy '+IP+':'+PORT);
      if Login<>'' then
        begin
          Result.Add('Socks5ProxyUsername '+Login);
          Result.Add('Socks5ProxyPassword '+Passw);
        end;
    end else
  if STYPE = 'HTTPS' then
    begin
      Result.Add('HTTPSProxy '+IP+':'+PORT);
      if Login<>'' then Result.Add('HTTPSProxyAuthenticator '+Login+':'+Passw);
    end;
end;

{ TLink }
constructor TLink.Create(Sender: TObject);
begin
  Url :='';
end;
destructor TLink.Destroy;
begin
  SetLength(Sockses,0);
end;
//��������� ������ ������ � ������ � ������
procedure TLink.AddS(IP,PORT: String; STYPE: String=''; LOGIN: String=''; PASSW: String='');
begin
  SetLength(Sockses, Length(Sockses)+1);
  Sockses[Length(Sockses)-1].IP :=IP;
  Sockses[Length(Sockses)-1].PORT :=PORT;
  Sockses[Length(Sockses)-1].STYPE :=STYPE;
  Sockses[Length(Sockses)-1].LOGIN :=LOGIN;
  Sockses[Length(Sockses)-1].PASSW :=PASSW;
end;
procedure TLink.AddS(Socks: TSocks);
begin
  SetLength(Sockses, Length(Sockses)+1);
  Sockses[Length(Sockses)-1].IP :=Socks.IP;
  Sockses[Length(Sockses)-1].PORT :=Socks.PORT;
  Sockses[Length(Sockses)-1].STYPE :=Socks.STYPE;
  Sockses[Length(Sockses)-1].LOGIN :=Socks.LOGIN;
end;
//������� ������ �� ������
procedure TLink.DelS;
Var i: Integer;
begin
  if Length(Sockses)>1 then
    begin
      for i:=1 to Length(Sockses)-1 do
          Sockses[i-1] :=Sockses[i];
      SetLength(Sockses,Length(Sockses)-1);
    end else SetLength(Sockses,0);
end;
//������������� ������, ������������
procedure TLink.SocksRandomize;
Var i,j,x: Word;
    dSocks: TSocks;
begin
  j :=Length(Sockses);
  Randomize;
  If j>0 then
    try
      For i:=0 to j-1 do
        begin
          dSocks :=Sockses[i];
          x :=Random(j);
          Sockses[i] :=Sockses[x];
          Sockses[x] :=dSocks;
        end;
    except
    end;
end;

end.

