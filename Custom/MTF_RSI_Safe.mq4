//+------------------------------------------------------------------+
//|                                                MTF_RSI_Safe.mq4   |
//|  多周期RSI（Multi-Timeframe RSI）— 不含未来函数                   |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  同时显示M1/M5/M15/H1/H4/D1六个周期的RSI值                        |
//|  多周期共振=强信号                                                 |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_minimum 0
#property indicator_maximum 100

input int InpRSIPeriod=14;

double rsiM1[],rsiM5[],rsiM15[],rsiH1[],rsiH4[],rsiD1[],buySignal[],sellSignal[];

int init() {
   color clrs[]={clrGray,clrYellow,clrOrange,clrDodgerBlue,clrMagenta,clrWhite};
   string nms[]={"M1","M5","M15","H1","H4","D1"};
   double *bufs[]={rsiM1,rsiM5,rsiM15,rsiH1,rsiH4,rsiD1};
   for(int i=0;i<6;i++){SetIndexStyle(i,DRAW_LINE,STYLE_SOLID,1,clrs[i]);SetIndexBuffer(i,bufs[i]);SetIndexLabel(i,"RSI_"+nms[i]);SetIndexEmptyValue(i,0);}
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(6,buySignal);SetIndexArrow(6,ARROW_BUY);SetIndexEmptyValue(6,EMPTY_VALUE);
   SetIndexStyle(7,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(7,sellSignal);SetIndexArrow(7,ARROW_SELL);SetIndexEmptyValue(7,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("MTF_RSI_Safe");return(0);
}
int deinit(){return(0);}

double CalcRSI(int tf,int shift,int per){
   double aG=0,aL=0;
   for(int j=0;j<per;j++){double ch=iClose(_Symbol,tf,shift+j)-iClose(_Symbol,tf,shift+j+1);if(ch>0)aG+=ch;else aL-=ch;}
   aG/=per;aL/=per;double rs=SafeDivide(aG,aL,0);return (aL<0.00000001)?100:100-100/(1+rs);
}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   int tfs[]={PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};
   double *bufs[]={rsiM1,rsiM5,rsiM15,rsiH1,rsiH4,rsiD1};

   for(int i=limit;i>=1;i--){
      for(int t=0;t<6;t++)bufs[t][i]=CalcRSI(tfs[t],iBarShift(_Symbol,tfs[t],iTime(_Symbol,_Period,i)),InpRSIPeriod);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--){
      int bCount=0,sCount=0;
      for(int t=0;t<6;t++){if(bufs[t][i]>50)bCount++;else sCount++;}
      // 全部6个周期RSI>50 → 全面多头
      if(bCount>=5)buySignal[i]=45;
      // 全部6个周期RSI<50 → 全面空头
      if(sCount>=5)sellSignal[i]=55;
   }
   if(Bars>0){for(int t=0;t<6;t++)bufs[t][0]=bufs[t][1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
