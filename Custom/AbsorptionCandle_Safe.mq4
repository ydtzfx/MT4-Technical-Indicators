//+------------------------------------------------------------------+
//|                                       AbsorptionCandle_Safe.mq4   |
//|  吸收K线 — 高成交量但价格净变动极小=多空剧烈博弈                   |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input double InpVolMult=2.0;input double InpMaxBodyPct=0.2; // 最大实体/范围比
double absorption[],absorptionBear[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,clrYellow);SetIndexBuffer(0,absorption);SetIndexArrow(0,ARROW_DOT);SetIndexLabel(0,"Absorption");SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,clrOrange);SetIndexBuffer(1,absorptionBear);SetIndexArrow(1,ARROW_DOT);SetIndexLabel(1,"AbsorptionBear");SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("Absorb_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){absorption[i]=absorptionBear[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   double avgV=0;for(int j=0;j<20;j++)avgV+=iVolume(_Symbol,_Period,limit+10+j);avgV/=20;
   for(int i=limit;i>=3;i++){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double r=h-l,body=MathAbs(c-o),v=iVolume(_Symbol,_Period,i),pc=iClose(_Symbol,_Period,i+1);
      // 高量+小实体+长影线=吸收
      if(v>avgV*InpVolMult&&body<r*InpMaxBodyPct){
         double lowerW=MathMin(o,c)-l,upperW=h-MathMax(o,c);
         if(lowerW>upperW*1.5)absorption[i]=l-3*Point; // 下影长=多方吸收
         else if(upperW>lowerW*1.5)absorptionBear[i]=h+3*Point; // 上影长=空方吸收
         // 吸收后价格往吸收方向走=确认
         if(absorption[i]!=EMPTY_VALUE&&c>pc)buySignal[i]=l-8*Point;
      }
   }
   return(0);}
