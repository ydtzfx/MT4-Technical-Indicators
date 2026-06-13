//+------------------------------------------------------------------+
//|                                          EhlersFisher_Safe.mq4    |
//|  Ehlers Fisher Transform — John Ehlers的DSP指标                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  对中位价应用Hilbert Transform后的Fisher Transform                  |
//|  极度减少滞后，极值点=精确的转折信号                               |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_level1 2
#property indicator_level2 -2

input int InpPeriod=10;

double fish[],trigger[],buySignal[],sellSignal[],smooth[],strongBuy[],strongSell[];

int init(){SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,fish);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"EhlersFish");SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrYellow);SetIndexBuffer(1,trigger);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Trigger");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexStyle(4,DRAW_HISTOGRAM,STYLE_SOLID,1);SetIndexBuffer(4,smooth);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexLabel(4,"Delta");SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(5,strongBuy);SetIndexArrow(5,ARROW_BUY);SetIndexEmptyValue(5,EMPTY_VALUE);SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(6,strongSell);SetIndexArrow(6,ARROW_SELL);SetIndexEmptyValue(6,EMPTY_VALUE);IndicatorDigits(3);IndicatorShortName("EhlersFish_Safe");return(0);}
int deinit(){return(0);}

int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   double price[],iComp[],qComp[],smoothPrice[];ArrayResize(price,Bars);ArrayResize(iComp,Bars);ArrayResize(qComp,Bars);ArrayResize(smoothPrice,Bars);
   for(int i=Bars-2;i>=1;i--)price[i]=(iHigh(_Symbol,_Period,i)+iLow(_Symbol,_Period,i))/2;
   // Hilbert Transform - 简化版正交滤波器
   for(int i=Bars-10;i>=1;i--){
      iComp[i]=0.0962*price[i]+0.5769*price[i+2]-0.5769*price[i+4]-0.0962*price[i+6];
      qComp[i]=0.0962*price[i+1]+0.5769*price[i+3]-0.5769*price[i+5]-0.0962*price[i+7];
      smoothPrice[i]=0.2*iComp[i]+0.8*(i>1?smoothPrice[i+1]:iComp[i]);
   }
   for(int i=limit;i>=1;i++){
      double mn=smoothPrice[i],mx=smoothPrice[i];for(int j=0;j<InpPeriod;j++){if(smoothPrice[i+j]<mn)mn=smoothPrice[i+j];if(smoothPrice[i+j]>mx)mx=smoothPrice[i+j];}
      double rng=mx-mn;double x=rng>0?2*(smoothPrice[i]-mn)/rng-1:0;x=MathMax(-0.999,MathMin(0.999,x));
      fish[i]=0.5*MathLog((1+x)/(1-x));trigger[i]=0.5*fish[i]+0.5*trigger[i+1];
      smooth[i]=fish[i]-fish[i+1];buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i++){
      bool priceUp=iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+2);
      // Strong Buy: 金叉 + 价格向上
      if(fish[i+1]<=trigger[i+1]&&fish[i]>trigger[i]&&smooth[i]>0&&priceUp)strongBuy[i]=fish[i]-0.8;
      // Strong Sell: 死叉 + 价格向下
      if(fish[i+1]>=trigger[i+1]&&fish[i]<trigger[i]&&smooth[i]<0&&!priceUp)strongSell[i]=fish[i]+0.8;
      // Normal Buy: 金叉
      if(fish[i+1]<=trigger[i+1]&&fish[i]>trigger[i]&&strongBuy[i]==EMPTY_VALUE)buySignal[i]=fish[i]-0.5;
      // Normal Sell: 死叉
      if(fish[i+1]>=trigger[i+1]&&fish[i]<trigger[i]&&strongSell[i]==EMPTY_VALUE)sellSignal[i]=fish[i]+0.5;
   }
   if(Bars>0){fish[0]=fish[1];trigger[0]=trigger[1];smooth[0]=smooth[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);}
