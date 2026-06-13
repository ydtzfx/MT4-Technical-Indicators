//+------------------------------------------------------------------+
//|                                   VolatilityTermStructure_Safe    |
//|  波动率期限结构 — 原创指标                                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：对比短/中/长三个周期的波动率，判断波动率结构                 |
//|  Contango(升水)：短期波动<长期波动=市场平静→趋势可能延续            |
//|  Backwardation(贴水)：短期波动>长期波动=市场紧张→可能变盘           |
//|  波动率结构突变是重要的市场状态转换信号                            |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5

input int InpShort=5,InpMid=20,InpLong=50;

double termSpread[],shortVol[],midVol[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,termSpread);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Vol Spread");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrTomato);SetIndexBuffer(1,shortVol);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Short Vol");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(2,midVol);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"Mid Vol");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(2);IndicatorShortName("VolTerm_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // 分别计算短/中/长期的ATR（作为波动率代理）
      double sVol=0,mVol=0,lVol=0;
      for(int j=0;j<InpLong;j++){
         double tr=GetTrueRange(_Symbol,_Period,i+j);
         lVol+=tr;if(j<InpMid)mVol+=tr;if(j<InpShort)sVol+=tr;
      }
      sVol/=InpShort;mVol/=InpMid;lVol/=InpLong;

      shortVol[i]=sVol;midVol[i]=mVol;
      // 期限价差 = (短期-中期)/中期 * 100（正值=近高远低，贴水结构）
      termSpread[i]=SafeDivide(100*(sVol-mVol),mVol,0);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=3;i--){
      // 波动率结构从贴水转为升水（市场平静下来）→ 可顺势交易
      if(termSpread[i+1]>10&&termSpread[i]<0&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=termSpread[i]-5;
      // 波动率结构从升水转为贴水（市场紧张起来）→ 可能变盘
      if(termSpread[i+1]<-10&&termSpread[i]>0)sellSignal[i]=termSpread[i]+5;
      // 极端贴水（恐慌）后回落
      if(termSpread[i+1]>30&&termSpread[i]<20)buySignal[i]=termSpread[i]-5;
   }
   if(Bars>0){termSpread[0]=termSpread[1];shortVol[0]=shortVol[1];midVol[0]=midVol[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
