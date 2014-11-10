void 
mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray	*prhs[]);


// row and column both start from 1. total_row is the total number of row

inline int getindex( int total_row, int row, int column)
{
   return (column-1)*total_row+row-1;
}