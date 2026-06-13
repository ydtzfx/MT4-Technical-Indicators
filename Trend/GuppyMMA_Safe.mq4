//+------------------------------------------------------------------+
//|                                                GuppyMMA_Safe.mq4  |
//|  顾比均线（Guppy MMA）— 不含未来函数                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  6条短期EMA(3,5,8,10,12,15)+6条长期EMA(30,35,40,45,50,60)         |
//|  短期组上穿长期组=趋势转多，短期组发散=趋势加速                    |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 16

input bool InpShowSignals=true;

double s3[],s5[],s8[],s10[],s12[],s15[];
double l30[],l35[],l40[],l45[],l50[],l60[];
double buySignal[],sellSignal[];
double strongBuy[],strongSell[];

int init() {
   color sc[6]={clrLimeGreen,clrLimeGreen,clrLime,clrLime,clrYellowGreen,clrYellowGreen};
   color lc[6]={clrTomato,clrTomato,clrOrangeRed,clrOrangeRed,clrOrange,clrOrange};
   double *shortBuf[6]={s3,s5,s8,s10,s12,s15};string sn[6]={"S3","S5","S8","S10","S12","S15"};
   double *longBuf[6]={l30,l35,l40,l45,l50,l60};string ln[6]={"L30","L35","L40","L45","L50","L60"};
   for(int i=0;i<6;i++){SetIndexStyle(i,DRAW_LINE,STYLE_SOLID,1,sc[i]);SetIndexBuffer(i,shortBuf[i]);SetIndexLabel(i,sn[i]);SetIndexEmptyValue(i,0);}
   for(int i=0;i<6;i++){SetIndexStyle(i+6,DRAW_LINE,STYLE_SOLID,1,lc[i]);SetIndexBuffer(i+6,longBuf[i]);SetIndexLabel(i+6,ln[i]);SetIndexEmptyValue(i+6,0);}
   SetIndexStyle(12,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(12,buySignal);SetIndexArrow(12,ARROW_BUY);SetIndexEmptyValue(12,EMPTY_VALUE);
   SetIndexStyle(13,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(13,sellSignal);SetIndexArrow(13,ARROW_SELL);SetIndexEmptyValue(13,EMPTY_VALUE);
   SetIndexBuffer(14,strongBuy);SetIndexStyle(14,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(14,233);SetIndexEmptyValue(14,EMPTY_VALUE);
   SetIndexBuffer(15,strongSell);SetIndexStyle(15,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(15,234);SetIndexEmptyValue(15,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("GuppyMMA_Safe");return(0);
}
int deinit(){return(0);}

double CalcE(double &p[],int per,int idx){double e=0;for(int i=idx+per;i<idx+per*2;i++)e+=p[i];e/=per;double a=2.0/(per+1);for(int i=idx+per-1;i>=idx;i--)e=p[i]*a+e*(1-a);return e;}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   int sp[]={3,5,8,10,12,15},lp[]={30,35,40,45,50,60};
   double *sb[6]={s3,s5,s8,s10,s12,s15},*lb[6]={l30,l35,l40,l45,l50,l60};

   for(int i=limit;i>=1;i--) {
      double p[200];for(int j=0;j<200&&(i+j<Bars);j++)p[j]=iClose(_Symbol,_Period,i+j);
      for(int k=0;k<6;k++){sb[k][i]=CalcE(p,sp[k],0);lb[k][i]=CalcE(p,lp[k],0);}
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   if(InpShowSignals) for(int i=limit;i>=1;i--) {
      strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
      // 强信号：交叉 + 中期确认(s5>l35) + 短期组发散(short bundle expanding)
      if(s3[i+1]<=l60[i+1]&&s3[i]>l60[i]&&s5[i]>l35[i]&&s3[i]-s15[i]>s3[i+1]-s15[i+1])
         strongBuy[i]=iLow(_Symbol,_Period,i)-15*Point;
      if(s3[i+1]>=l60[i+1]&&s3[i]<l60[i]&&s5[i]<l35[i]&&s15[i]-s3[i]>s15[i+1]-s3[i+1])
         strongSell[i]=iHigh(_Symbol,_Period,i)+15*Point;
      // 标准信号：最短短期组上穿最长长期组 = 趋势全面转多
      if(s3[i+1]<=l60[i+1]&&s3[i]>l60[i])buySignal[i]=iLow(_Symbol,_Period,i)-15*Point;
      if(s3[i+1]>=l60[i+1]&&s3[i]<l60[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+15*Point;
   }
   if(Bars>0){for(int k=0;k<6;k++){sb[k][0]=sb[k][1];lb[k][0]=lb[k][1];}buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
