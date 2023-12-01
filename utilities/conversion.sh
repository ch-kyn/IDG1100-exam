#!/bin/bash

# ToS (https://api.met.no/doc/TermsOfService): 5. When using requests with latitude/longitude, truncate all coordinates to max 4 decimals for traffic reasons

# converts degree-type coordinates into decimal coordinates by reading from stdin ('$0' refers to the entire input record), split e.g. 59°54′48″N into three arrays by specifing the delimiters (°|′|″);
# use math and print the coordinate as a field (due to all the coordinates having greater than 4 decimals, I truncated all to four decimal floats by changing the 'printf' structure to "%.4f")

function degrees_converter(){
    while read -r deg; do
        awk '
            {
                split($0, arr, /°|′|″/)
                dir = (arr[4] ~ /[NE]/) ? 1 : -1
                dec = dir * (arr[1] + arr[2]/60 + arr[3]/3600)
                printf("%.4f", dec)
            }
        ' <<< "$deg"
    done
}
