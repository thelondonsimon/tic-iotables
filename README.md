# tic-iotables

This repository contains scripts for analysing Input-Output tables to obtain output and employment multipliers for different industries.

It uses National Accounts Data from the Australian Bureau of Statistics: <https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-input-output-tables/latest-release>

## abs-io-example.R

Provides a worked example to reproduce the analysis in the ABS Information Paper [*52460: Introduction to Input Output Multipliers*](./52460%20-%20Information%20Paper%20-%20Introduction%20to%20Input%20Output%20Multipliers.pdf). The data in these examples come from the information paper itself. This, therefore, provides verification of the calculations used to derive the output and employment multipliers in subsequent scripts which draw on tables in recently published National Account data.

## abs-io-XXXX.R

These scripts process Input-Output tables for a specific financial year to obtain output and employment multipliers.

## incolink-employment-calculator.xlsx

An Excel-based calculator developed using industry-specific multiplier tables derived using the scripts above.
