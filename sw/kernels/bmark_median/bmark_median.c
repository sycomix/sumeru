// See LICENSE for license details.

//**************************************************************************
// Median filter bencmark
//--------------------------------------------------------------------------
//
// This benchmark performs a 1D three element median filter. The
// input data (and reference data) should be generated using the
// median_gendata.pl perl script and dumped to a file named
// dataset1.h.

#include <machine/constants.h>
#include <machine/csr.h>

#include "util.h"

#include "median.h"

//--------------------------------------------------------------------------
// Input/Reference Data

#include "dataset1.h"

//--------------------------------------------------------------------------
// Main

#define HZ 75000000
#define Too_Small_Time 1
#define CLOCK_TYPE "rdtime()"
#define Start_Timer() Begin_Time = rdtime();
#define Stop_Timer() End_Time = rdtime();

long            Begin_Time,
                End_Time;

long            Ticks;
int             Number_Of_Runs;

int main( int argc, char* argv[] )
{
  int results_data[DATA_SIZE];

  // Do the filter
  Number_Of_Runs = 1000;
  while (1) {
    Start_Timer();
    for (int i = 0; i < Number_Of_Runs; ++i)
      median( DATA_SIZE, input_data, results_data );
    Stop_Timer();

    Ticks = End_Time - Begin_Time;

    // Check the results
    if (verify( DATA_SIZE, results_data, verify_data ) == 0) 
      printf("Verify OK\n");
    else
      printf("Verify FAIL\n");

    printf("Total runs:                          %d\n", Number_Of_Runs);
    printf("Total ticks for all runs:            %d\n", Ticks);
  }

  return 0;
}
