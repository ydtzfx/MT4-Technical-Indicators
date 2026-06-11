//+------------------------------------------------------------------+
//|                                              Tweezer_Safe.mq4     |
//|  平头/平底检测（Tweezer Tops/Bottoms）                             |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input double InpTolerance=0.1; // 容忍度(%ATR)
double tweezerTop[],tweezerBot[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(0,tweezerTop);SetIndexArrow(0,ARROW_SELL);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(1,tweezerBot);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("Tweezer_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){tweezerTop[i]=tweezerBot[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   double atr=0;for(int j=0;j<14;j++)atr+=GetTrueRange(_Symbol,_Period,limit+10+j);atr/=14;double tol=InpTolerance*atr/100;
   for(int i=limit;i>=3;i--){
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i),o=iOpen(_Symbol,_Period,i);
      double ph=iHigh(_Symbol,_Period,i+1),pl=iLow(_Symbol,_Period,i+1);
      // 平顶：连续两根的高点几乎相同
      if(MathAbs(h-ph)<tol&&c<o&&iClose(_Symbol,_Period,i+1)<iOpen(_Symbol,_Period,i+1))tweezerTop[i]=h+5*Point;
      // 平底：连续两根的低点几乎相同
      if(MathAbs(l-pl)<tol&&c>o&&iClose(_Symbol,_Period,i+1)>iOpen(_Symbol,_Period,i+1))tweezerBot[i]=l-5*Point;
      // 确认：平顶后下一根突破低点=反转确认
      if(tweezerTop[i+1]!=EMPTY_VALUE&&c<pl)sellSignal[i]=h+10*Point;
      if(tweezerBot[i+1]!=EMPTY_VALUE&&c>ph)buySignal[i]=l-10*Point;
   }
   return(0);}
