//+------------------------------------------------------------------+
//|                                                   CDP_Safe.mq4    |
//|  逆势操作指标（CDP）— 不含未来函数                                |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式（基于前一周期OHLC）：                                        |
//|  CDP (Pivot) = (H + L + C) / 3                                    |
//|  R1 = 2*CDP - L    S1 = 2*CDP - H                                 |
//|  R2 = CDP + (H-L)   S2 = CDP - (H-L)                              |
//|  R3 = H + 2*(CDP-L) S3 = L - 2*(H-CDP)                            |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 价格突破R1并站稳 → 趋势转强                                   |
//|  - 价格跌破S1并站稳 → 趋势转弱                                   |
//|  - CDP是日内多空分界线                                             |
//|  支持自定义周期（默认24根H1=1天）                                 |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9

input int  InpDayBars = 24;     // 日级K线数（H1=24, H4=6, D1=1）
input bool InpShowExtended = true; // 显示R3/S3扩展线
input color InpCDPColor = clrWhite;
input color InpR1S1Color = clrYellow;
input color InpR2S2Color = clrOrange;
input color InpR3Color = clrTomato;
input color InpS3Color = clrLimeGreen;

double cdp[],r1[],s1[],r2[],s2[],r3[],s3[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,InpCDPColor);SetIndexBuffer(0,cdp);SetIndexLabel(0,"CDP");
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,InpR1S1Color);SetIndexBuffer(1,r1);SetIndexLabel(1,"R1");
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,1,InpR1S1Color);SetIndexBuffer(2,s1);SetIndexLabel(2,"S1");
   SetIndexStyle(3,DRAW_LINE,STYLE_DOT,1,InpR2S2Color);SetIndexBuffer(3,r2);SetIndexLabel(3,"R2");
   SetIndexStyle(4,DRAW_LINE,STYLE_DOT,1,InpR2S2Color);SetIndexBuffer(4,s2);SetIndexLabel(4,"S2");
   SetIndexStyle(5,DRAW_LINE,STYLE_DOT,1,InpR3Color);SetIndexBuffer(5,r3);SetIndexLabel(5,"R3");
   SetIndexStyle(6,DRAW_LINE,STYLE_DOT,1,InpS3Color);SetIndexBuffer(6,s3);SetIndexLabel(6,"S3");
   SetIndexStyle(7,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(7,buySignal);SetIndexArrow(7,ARROW_BUY);SetIndexEmptyValue(7,EMPTY_VALUE);
   SetIndexStyle(8,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(8,sellSignal);SetIndexArrow(8,ARROW_SELL);SetIndexEmptyValue(8,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("CDP_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   // 初始化缓冲区
   for(int i=limit;i>=0;i--){cdp[i]=0;r1[i]=0;s1[i]=0;r2[i]=0;s2[i]=0;r3[i]=0;s3[i]=0;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}

   // 计算每个"日"周期的CDP及支撑阻力位
   for(int i=limit+InpDayBars;i>=InpDayBars;i--) {
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i);
      for(int j=1;j<InpDayBars;j++) {
         double hh=iHigh(_Symbol,_Period,i+j),ll=iLow(_Symbol,_Period,i+j);
         if(hh>h)h=hh;if(ll<l)l=ll;
      }
      double c=iClose(_Symbol,_Period,i);
      double pivot=(h+l+c)/3.0;
      cdp[i]=pivot;r1[i]=2*pivot-l;s1[i]=2*pivot-h;
      r2[i]=pivot+(h-l);s2[i]=pivot-(h-l);
      if(InpShowExtended){r3[i]=h+2*(pivot-l);s3[i]=l-2*(h-pivot);}
   }

   // 信号（bar[1]+确认）
   for(int i=limit;i>=1;i--) {
      double close=iClose(_Symbol,_Period,i),close1=iClose(_Symbol,_Period,i+1);
      // 价格从CDP下方突破到上方 → 买入
      if(close1<=cdp[i+1]&&close>cdp[i])buySignal[i]=s1[i]-10*Point;
      // 价格从CDP上方跌破到下方 → 卖出
      if(close1>=cdp[i+1]&&close<cdp[i])sellSignal[i]=r1[i]+10*Point;
      // 突破R1阻力 → 强势追多
      if(close1<=r1[i+1]&&close>r1[i])buySignal[i]=s1[i]-10*Point;
      // 跌破S1支撑 → 强势追空
      if(close1>=s1[i+1]&&close<s1[i])sellSignal[i]=r1[i]+10*Point;
   }
   return(0);
}
