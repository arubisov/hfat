
/*
 mex file for extracting market order
*/

#include <stdio.h>
#include <memory.h>
#include <math.h>
#include <cfloat>
#include "mex.h"
#include "market_order_extraction.h"

using namespace std;




void 
mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray	*prhs[])
{
    /*  nlhs Number of expected mxArrays (Left Hand Side) 
     *  plhs Array of pointers to expected outputs 
     *  nrhs Number of inputs (Right Hand Side) 
     *  prhs Array of pointers to input data. 
     * 
     *  The input data is read-only and should not be altered by your mexFunction  
     *
     * It is important to note that the data inside the array is in column 
     * major order. Instead of reading a matrix's values across and then down, 
     * the values are read down and then across.
     *
     * Array creation mxCreateNumericArray, mxCreateCellArray, mxCreateCharArray 
     * Array access mxGetPr, mxGetPi, mxGetM, mxGetData, mxGetCell 
     * Array modification mxSetPr, mxSetPi, mxSetData, mxSetField 
     * Memory management mxMalloc, mxCalloc, mxFree, mexMakeMemoryPersistent, mexAtExit, mxDestroyArray, memcpy 
     *
     */
    
   
    /* read in the data and the time steps */
    double* p_Event = mxGetPr(prhs[0]);
    int nt = mxGetM(prhs[0]);

    double* p_SellVolume = mxGetPr(prhs[1]);

    double* p_SellPrice = mxGetPr(prhs[2]);

	double* p_BuyVolume = mxGetPr(prhs[3]);

	double* p_BuyPrice = mxGetPr(prhs[4]);

	// ************ first just count the number of MOs **************
	int count = 1;
	for( int n = 1; n < nt; )
	{
		int finished = 0;
		while ((p_Event[getindex(nt,n,3)] != 69) && ( p_Event[getindex(nt,n,3)] != 70))
		{
			n++;
			if (n > nt)
			{
				finished = 1;
				break;
			}
		}
		if (finished)
			break;

		int buysell = (p_Event[getindex(nt,n,7)] == 0) ? 0 : 1;

		double now = p_Event[getindex(nt,n,1)];
		int nend=n;
		while (    (p_Event[getindex(nt,nend,7)] == buysell) && (p_Event[getindex(nt,nend,1)] == now)
			    && ((p_Event[getindex(nt,nend,3)] == 69) || (p_Event[getindex(nt,nend,3)] == 70)  )   )
		{
			nend++;
			if (nend > nt)
				break;
		}
		nend--;

		count++;
		n=nend+1;

	}

	// *** now create array and store all the info ***

	// returns are in this variable
	//column 1: time of event
	//column 2: best bid price prior to MO
	//column 3: best ask price prior to MO
	//column 4: best bid volume prior to MO
	//column 5: best ask volume prior to MO
	//column 6: average executed price per share
	//column 7: consolidated volume of MO
	//column 8: buy (-1) sell (+1) indicator
	//column 9: highest price paid or lowest price received for that MO
	//column 10: exchange

	//column 11-15: 5 best bid prices prior to MO
	//column 16-20: 5 best bid volumes prior to MO
	//column 21-25: 5 best ask prices prior to MO
	//column 26-30: 5 best ask volumes prior to MO

	int NMO = count - 1;
	plhs[0] = mxCreateDoubleMatrix(NMO,30,mxREAL);

	// create pointers to the arrays so we can fill them directly
	double* p0 = mxGetPr(plhs[0]);

	count = 1;
	for( int n = 1; n < nt; )
	{
		int finished = 0;
		while ((p_Event[getindex(nt,n,3)] != 69) && ( p_Event[getindex(nt,n,3)] != 70) )
		{
			n++;
			if (n > nt)
			{
				finished = 1;
				break;
			}
		}
		if (finished)
			break;

		p0[getindex(NMO,count,1)] = p_Event[getindex(nt,n,1)];
		p0[getindex(NMO,count,2)] = p_BuyPrice[getindex(nt,n-1,1)];
		p0[getindex(NMO,count,3)] = p_SellPrice[getindex(nt,n-1,1)];
		p0[getindex(NMO,count,4)] = p_BuyVolume[getindex(nt,n-1,1)];
		p0[getindex(NMO,count,5)] = p_SellVolume[getindex(nt,n-1,1)];
		p0[getindex(NMO,count,10)] = p_Event[getindex(nt,n,6)];

		for(int k = 0; k < 5; k++)
		{
			p0[getindex(NMO,count,11+k)] = p_BuyPrice[getindex(nt,n-1,1+k)];
			p0[getindex(NMO,count,16+k)] = p_BuyVolume[getindex(nt,n-1,1+k)];
			p0[getindex(NMO,count,21+k)] = p_SellPrice[getindex(nt,n-1,1+k)];
			p0[getindex(NMO,count,26+k)] = p_SellVolume[getindex(nt,n-1,1+k)];
		}

		int buysell = (p_Event[getindex(nt,n,7)] == 0) ? 0 : 1;

		int nend=n;
		while ( (p_Event[getindex(nt,nend,7)] == buysell) && (p_Event[getindex(nt,nend,1)] == p0[getindex(NMO,count,1)]) 
			    && ((p_Event[getindex(nt,nend,3)] == 69) || (p_Event[getindex(nt,nend,3)] == 70)  )  
			   )
		{
			nend++;
			if (nend > nt)
				break;
		}
		nend--;

		double temp_vol = p_Event[getindex(nt,n,4)], 
			   temp_price = p_Event[getindex(nt,n,5)], 
			   temp_cost = p_Event[getindex(nt,n,4)]*p_Event[getindex(nt,n,5)], 
			   temp_highest = p_Event[getindex(nt,n,5)], 
			   temp_lowest = p_Event[getindex(nt,n,5)];

		for(int j = n+1; j <= nend; j++)
		{
			temp_vol += p_Event[getindex(nt,j,4)];
			temp_price = p_Event[getindex(nt,j,5)];
			temp_cost += p_Event[getindex(nt,j,4)]* temp_price;
			temp_highest = (temp_highest < temp_price) ? temp_price : temp_highest;
			temp_highest = (temp_highest < temp_price) ? temp_price : temp_highest;
			temp_lowest = (temp_lowest < temp_price) ? temp_lowest : temp_price;
		}

		p0[getindex(NMO,count,6)] = temp_cost/temp_vol;
		p0[getindex(NMO,count,7)] = temp_vol;
		p0[getindex(NMO,count,8)] = ( buysell == 0 ) ? -1 : +1;
		p0[getindex(NMO,count,9)] = ( buysell == 0 ) ? temp_highest : temp_lowest; 

		if ( count == 1 )
		{
			count --;
			count ++;
		}

		count++;
		n=nend+1;

	}

}