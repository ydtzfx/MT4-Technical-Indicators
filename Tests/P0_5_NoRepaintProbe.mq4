//+------------------------------------------------------------------+
//| P0_5_NoRepaintProbe.mq4                                          |
//| Closed-bar signal persistence probe for MT4 Strategy Tester.      |
//+------------------------------------------------------------------+
#property copyright "P0.5 verification"
#property version   "1.01"

input int InpTrackedBars = 8;
input int InpWarmupBars = 600;
input int InpMinTransitions = 20;
input double InpTolerance = 0.00000001;

double prevValues[23][8];
bool initialized=false;
datetime lastBarTime=0;
int checks=0;
int violations=0;
int transitions=0;
int startCalls=0;
int eligibleCalls=0;
int minBarsSeen=2147483647;
int maxBarsSeen=0;
int fileHandle=INVALID_HANDLE;

string ChannelName(int c)
{
   if(c==0)return("MA.buy"); if(c==1)return("MA.sell"); if(c==2)return("MA.strongBuy"); if(c==3)return("MA.strongSell");
   if(c==4)return("RSI.buy"); if(c==5)return("RSI.sell"); if(c==6)return("RSI.strongBuy"); if(c==7)return("RSI.strongSell");
   if(c==8)return("MACD.buy"); if(c==9)return("MACD.sell"); if(c==10)return("MACD.strongBuy"); if(c==11)return("MACD.strongSell");
   if(c==12)return("Stoch.buy"); if(c==13)return("Stoch.sell"); if(c==14)return("Stoch.strongBuy"); if(c==15)return("Stoch.strongSell");
   if(c==16)return("Ichimoku.buy"); if(c==17)return("Ichimoku.sell"); if(c==18)return("Ichimoku.strongBuy");
   if(c==19)return("MTF_RSI.buy"); if(c==20)return("MTF_RSI.sell");
   if(c==21)return("Backtest.buy"); return("Backtest.sell");
}

double ReadChannel(int c,int shift)
{
   if(c==0)return(iCustom(NULL,0,"Trend\\MA_Safe",2,shift));
   if(c==1)return(iCustom(NULL,0,"Trend\\MA_Safe",3,shift));
   if(c==2)return(iCustom(NULL,0,"Trend\\MA_Safe",4,shift));
   if(c==3)return(iCustom(NULL,0,"Trend\\MA_Safe",5,shift));
   if(c==4)return(iCustom(NULL,0,"Oscillators\\RSI_Safe",1,shift));
   if(c==5)return(iCustom(NULL,0,"Oscillators\\RSI_Safe",2,shift));
   if(c==6)return(iCustom(NULL,0,"Oscillators\\RSI_Safe",3,shift));
   if(c==7)return(iCustom(NULL,0,"Oscillators\\RSI_Safe",4,shift));
   if(c==8)return(iCustom(NULL,0,"Oscillators\\MACD_Safe",3,shift));
   if(c==9)return(iCustom(NULL,0,"Oscillators\\MACD_Safe",4,shift));
   if(c==10)return(iCustom(NULL,0,"Oscillators\\MACD_Safe",5,shift));
   if(c==11)return(iCustom(NULL,0,"Oscillators\\MACD_Safe",6,shift));
   if(c==12)return(iCustom(NULL,0,"Oscillators\\Stochastic_Safe",2,shift));
   if(c==13)return(iCustom(NULL,0,"Oscillators\\Stochastic_Safe",3,shift));
   if(c==14)return(iCustom(NULL,0,"Oscillators\\Stochastic_Safe",4,shift));
   if(c==15)return(iCustom(NULL,0,"Oscillators\\Stochastic_Safe",5,shift));
   if(c==16)return(iCustom(NULL,0,"Trend\\Ichimoku_Safe",5,shift));
   if(c==17)return(iCustom(NULL,0,"Trend\\Ichimoku_Safe",6,shift));
   if(c==18)return(iCustom(NULL,0,"Trend\\Ichimoku_Safe",7,shift));
   if(c==19)return(iCustom(NULL,0,"Custom\\MTF_RSI_Safe",6,shift));
   if(c==20)return(iCustom(NULL,0,"Custom\\MTF_RSI_Safe",7,shift));
   if(c==21)return(iCustom(NULL,0,"Custom\\Backtest_Safe",2,shift));
   return(iCustom(NULL,0,"Custom\\Backtest_Safe",3,shift));
}

bool SameValue(double a,double b)
{
   if(a==EMPTY_VALUE && b==EMPTY_VALUE)return(true);
   if(a==EMPTY_VALUE || b==EMPTY_VALUE)return(false);
   double scale=MathMax(1.0,MathMax(MathAbs(a),MathAbs(b)));
   return(MathAbs(a-b)<=InpTolerance*scale);
}

void Capture()
{
   int maxBars=MathMin(InpTrackedBars,8);
   for(int c=0;c<23;c++)
      for(int s=1;s<=maxBars;s++)
         prevValues[c][s-1]=ReadChannel(c,s);
}

void Compare()
{
   int maxBars=MathMin(InpTrackedBars,8);
   for(int c=0;c<23;c++)
   {
      for(int s=1;s<=maxBars;s++)
      {
         double now=ReadChannel(c,s+1);
         double before=prevValues[c][s-1];
         checks++;
         if(!SameValue(now,before))
         {
            violations++;
            if(fileHandle!=INVALID_HANDLE)
               FileWrite(fileHandle,"VIOLATION",ChannelName(c),TimeToString(iTime(NULL,0,s+1),TIME_DATE|TIME_MINUTES),before,now,"","","");
         }
      }
   }
}

int OnInit()
{
   fileHandle=FileOpen("p0_5_no_repaint.csv",FILE_CSV|FILE_WRITE,',');
   if(fileHandle!=INVALID_HANDLE)FileWrite(fileHandle,"kind","channel","bar_time","before","after","checks","violations","transitions","start_calls","eligible_calls","min_bars","max_bars");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(fileHandle!=INVALID_HANDLE)
   {
      FileWrite(fileHandle,"SUMMARY","","","","",checks,violations,transitions,startCalls,eligibleCalls,minBarsSeen,maxBarsSeen);
      FileClose(fileHandle);
   }
}

void ProcessTick()
{
   startCalls++;
   if(Bars<minBarsSeen)minBarsSeen=Bars;
   if(Bars>maxBarsSeen)maxBarsSeen=Bars;
   if(Bars<InpWarmupBars)return;
   if(Bars<InpTrackedBars+2)return;
   eligibleCalls++;
   datetime t=Time[0];
   if(t==0 || t==lastBarTime)return;
   lastBarTime=t;
   if(initialized)
   {
      Compare();
      transitions++;
   }
   Capture();
   initialized=true;
}

void OnTick()
{
   ProcessTick();
}
