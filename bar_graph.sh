#!/bin/bash
declare -A matrix
for ((i=0;i<8;i++)) do
   for ((j=0;j<100;j++)) do
       matrix[$i,$j]=$((RANDOM%16))
   done
done

for ((i=0;i<8;i++)) do
   for ((j=0;j<100;j++)) do
       color=${matrix[$i,$j]}
       # Convert the number to a hexadecimal color code
       color_code=$(printf '#%02x%02x%02x' $color $color $color)
       # Print a square unicode character with the corresponding color
       echo -ne "\033[38;5;${color}m\u2588\033[0m "
   done
   echo ""
done
