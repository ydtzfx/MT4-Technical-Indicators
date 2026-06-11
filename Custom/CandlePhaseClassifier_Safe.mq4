//+------------------------------------------------------------------+
//|                                      CandlePhaseClassifier_Safe   |
//|  K线相位分类 — 每根K线属于推动/修正/盘整中的哪一类                 |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -1
#property indicator_maximum 1
double phase[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,phase);SetIndexLabel(0,"Phase");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("Phase_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-50;if(limit<0)limit=0;
   double avgR=0;for(int j=0;j<20;j++)avgR+=iHigh(_Symbol,_Period,limit+10+j)-iLow(_Symbol,_Period,limit+10+j);avgR/=20;
   for(int i=limit;i>=1;i++){
      double r=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i),b=MathAbs(iClose(_Symbol,_Period,i)-iOpen(_Symbol,_Period,i));
      double upW=(iHigh(_Symbol,_Period,i)-MathMax(iOpen(_Symbol,_Period,i),iClose(_Symbol,_Period,i)))/MathMax(r,_Point);
      double loW=(MathMin(iOpen(_Symbol,_Period,i),iClose(_Symbol,_Period,i))-iLow(_Symbol,_Period,i))/MathMax(r,_Point);
      // 推动相位：大实体+小影线+宽幅            正=多头推动, 负=空头推动
      // 修正相位：小实体+长影线+窄幅              0=盘整/修正
      bool impulse=(b>r*0.5&&r>avgR*0.8);bool corrective=(b<r*0.3||r<avgR*0.4);
      if(impulse&&iClose(_Symbol,_Period,i)>iOpen(_Symbol,_Period,i))phase[i]=1;
      else if(impulse&&iClose(_Symbol,_Period,i)<iOpen(_Symbol,_Period,i))phase[i]=-1;
      else phase[i]=0;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=3;i++){if(phase[i+1]==0&&phase[i]==1)buySignal[i]=0.5;if(phase[i+1]==0&&phase[i]==-1)sellSignal[i]=-0.5;}
   if(Bars>0){phase[0]=phase[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}return(0);}
