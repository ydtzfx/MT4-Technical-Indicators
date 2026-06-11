//+------------------------------------------------------------------+
//|                                          WickReversal_Safe.mq4    |
//|  影线反转 — 长影线在趋势末端的多种反转变体                         |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpTrendBars=5;
double wickRevUp[],wickRevDn[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(0,wickRevUp);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(1,wickRevDn);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("WickRev_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){wickRevUp[i]=wickRevDn[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(int i=limit;i>=5;i++){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i),r=h-l;if(r<_Point)continue;
      double loW=(MathMin(o,c)-l)/r,upW=(h-MathMax(o,c))/r,body=MathAbs(c-o)/r;
      // 判断趋势方向
      bool trendDown=iClose(_Symbol,_Period,i+1)<iClose(_Symbol,_Period,i+InpTrendBars);
      bool trendUp=iClose(_Symbol,_Period,i+1)>iClose(_Symbol,_Period,i+InpTrendBars);
      // 下跌趋势+极长下影(>70%)+小实体=卖方枯竭
      if(trendDown&&loW>0.7&&body<0.3)wickRevUp[i]=l-8*Point;
      // 上涨趋势+极长上影(>70%)+小实体=买方枯竭
      if(trendUp&&upW>0.7&&body<0.3)wickRevDn[i]=h+8*Point;
      // 确认：下根K线沿反转方向
      if(wickRevUp[i+1]!=EMPTY_VALUE&&c>iHigh(_Symbol,_Period,i+1))buySignal[i]=l-12*Point;
      if(wickRevDn[i+1]!=EMPTY_VALUE&&c<iLow(_Symbol,_Period,i+1))sellSignal[i]=h+12*Point;
   }return(0);}
