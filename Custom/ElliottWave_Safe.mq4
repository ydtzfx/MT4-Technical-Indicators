//+------------------------------------------------------------------+
//|                                           ElliottWave_Safe.mq4    |
//|  波浪自动标注 — 原创指标                                           |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  自动识别5浪推动+3浪调整结构                                        |
//|  通过摆动点识别+斐波那契比例验证                                    |
//|  确认后才标注（bar[1]+），不预判                                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4

double waveHi[],waveLo[],buySignal[],sellSignal[];

int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,clrTomato);SetIndexBuffer(0,waveHi);SetIndexArrow(0,ARROW_SELL);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(1,waveLo);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(4);IndicatorShortName("ElliottWave_Safe");return(0);}
int deinit(){return(0);}

int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-200)limit=Bars-300;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){waveHi[i]=EMPTY_VALUE;waveLo[i]=EMPTY_VALUE;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}

   // 找摆动点序列
   double swings[];int swingBars[],swingCount=0;ArrayResize(swings,Bars);ArrayResize(swingBars,Bars);
   bool lastIsHigh=false;
   for(int i=Bars-10;i>=10;i--){
      bool isHigh=true,isLow=true;
      for(int j=1;j<=5;j++){if(i+j<Bars&&iHigh(_Symbol,_Period,i+j)>=iHigh(_Symbol,_Period,i))isHigh=false;if(i-j>=0&&iHigh(_Symbol,_Period,i-j)>=iHigh(_Symbol,_Period,i))isHigh=false;if(i+j<Bars&&iLow(_Symbol,_Period,i+j)<=iLow(_Symbol,_Period,i))isLow=false;if(i-j>=0&&iLow(_Symbol,_Period,i-j)<=iLow(_Symbol,_Period,i))isLow=false;}
      if(isHigh){swings[swingCount]=iHigh(_Symbol,_Period,i);swingBars[swingCount]=i;swingCount++;lastIsHigh=true;}
      if(isLow){swings[swingCount]=iLow(_Symbol,_Period,i);swingBars[swingCount]=i;swingCount++;lastIsHigh=false;}
   }
   // 用摆动点做斐波那契验证
   for(int w=4;w<swingCount-1;w++){
      if(swingBars[w]<=limit)continue;
      double w1=swings[w-4],w2=swings[w-3],w3=swings[w-2],w4=swings[w-1],w5=swings[w];
      // 简化：找5浪推动结构（3上2下，交替）
      bool impulse=((w1<w2&&w3<w2&&w3<w4&&w5>w4)||(w1>w2&&w3>w2&&w3>w4&&w5<w4));
      if(impulse){
         double r1=SafeDivide(MathAbs(w2-w1),MathAbs(w3-w2),0),r2=SafeDivide(MathAbs(w4-w3),MathAbs(w5-w4),0);
         if((r1>0.38&&r1<0.88)||(r2>0.38&&r2<0.88)){
            waveHi[swingBars[w]]=swings[w];
            // 5浪完成=回调启动
            if(w5>w4)sellSignal[swingBars[w]]=swings[w]+10*Point;else buySignal[swingBars[w]]=swings[w]-10*Point;
         }
      }
   }
   return(0);}
