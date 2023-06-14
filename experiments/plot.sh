#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")

echo "plot Figure 10"
bash "${SCRIPT_PATH}/plot/figure10/plot.sh"
echo "output: ${SCRIPT_PATH}/log/figure/figure10.png"
echo ""

echo "plot Figure 7"
bash "${SCRIPT_PATH}/plot/figure7/plot.sh"
echo "output: ${SCRIPT_PATH}/log/figure/figure7.png"
echo ""

echo "plot Figure 8"
bash "${SCRIPT_PATH}/plot/figure8/plot.sh"
echo "output: ${SCRIPT_PATH}/log/figure/figure8.png"
echo ""

echo "plot Figure 9"
bash "${SCRIPT_PATH}/plot/figure9/plot.sh"
echo "output: ${SCRIPT_PATH}/log/figure/figure9.png"
echo ""

echo "finish plotting."