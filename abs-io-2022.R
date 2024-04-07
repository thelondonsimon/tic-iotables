#############
#
# This script derives industry-specific output and employment multipliers
# from ABS Input-Output tables for 2021-2022
#
#############

library(tidyverse) # load tidyverse for data manipulation


# abs-io-2022-detailed.csv contains data from Table 5 of the Input-Output Tables of
# the ABS National Accounts
# TABLE 5: INDUSTRY BY INDUSTRY FLOW TABLE (DIRECT ALLOCATION OF IMPORTS)
table1 <- read.csv("data/abs-io-2022-detailed.csv", header = TRUE, row.names = 1)

# as i/o tables commonly include additional rows and columns which are not part of the
# flows between industries, specifying the number of industries allows isolating just that data
numIndustries <- 115

# create a matrix representing the industry data
table1_industries <- as.matrix(table1[1:numIndustries,1:numIndustries])

# extract the Australian production value for each industry from Table 1
total_output <- as.numeric(table1["Australian Production",1:numIndustries])
# replicate the vector as a matrix so it has the dimension as table1_industries and can be
# used in matrix division
total_output_matrix <- matrix(rep(total_output, nrow(table1_industries)), nrow = nrow(table1_industries), byrow = TRUE)

# derive matrix A - (1) in Table 4 on page 11
# this corresponds to a subset of the Direct Requirements Matrix (Table 2, page 7)
A <- table1_industries / total_output_matrix

# each industry's first round effects is calculated using the column totals
# shown in (2) of Table 4 on page 11
first_round_effects = colSums(A)

# calculate the Leontief inverse of matrix A - (2) in Table 4 on page 11
A_Leontief_Inverse <- solve(diag(nrow(A)) - A)

# each industry's simple multiplier is calculated using the column totals
simple_multipliers = colSums(A_Leontief_Inverse)

# industrial support effects are the effects of the second and subsequent rounds of induced production
industrial_support_effects <- simple_multipliers - 1 - first_round_effects
production_induced_effects <- first_round_effects + industrial_support_effects

# to create the B matrix, the A matrix needs to be extended with the following data
# from the Direct Requirements Coefficients matrix (Table 6)
# - the Wages row 
# - the Final consumption expenditure column
additional <- read.csv('data/abs-io-2022-additional.csv', header = TRUE, row.names = 1)
wages <- as.numeric(additional["Compensation of employees",]) / 100
B <- rbind(A,wages)
consumption <- c(as.numeric(additional["Household final consumption expenditure",]),0)
consumption <- ifelse(is.na(consumption),0,consumption) / 100
B <- cbind(B,consumption)

# calculate the Leontief inverse of matrix B - (2) in Table 4 on page 11
B_Leontief_Inverse <- solve(diag(nrow(B)) - B)
# the B* matrix is formed by taking just the 7x7 industry matrix of B_Leontief_Inverse
# this corresponds to (3) in Table 4 on page 11 (note, this table is identified as incorrect)
B_Star <- B_Leontief_Inverse[-(numIndustries+1),-(numIndustries+1)]
# the total multipliers are calculated as the column totals of B*
total_multipliers <- colSums(B_Star)

# consumption induced effects = total multiplier - simple multiplier (p 8-9)
consumption_induced_effects <- total_multipliers - simple_multipliers

# Table 5, page 12
output_multipliers <- tibble(
  Industry = colnames(A),
  `Initial effects` = 1,
  `First round effects` = first_round_effects,
  `Industrial support effects` = industrial_support_effects,
  `Production induced effects` = production_induced_effects,
  `Consumption induced effects` = consumption_induced_effects,
  `Simple multipliers` = simple_multipliers,
  `Total multipliers` = total_multipliers
)

# employment multipliers
employees <- as.numeric(table1["Employees",1:numIndustries])
employment_coefficients <- employees / total_output

emp_initial_effects <- employment_coefficients
emp_first_round_effects <- numeric(numIndustries)

for (i in 1:numIndustries) {
  emp_first_round_effects[i] <- sum(A[, i] * employment_coefficients)
}

emp_simple_multipliers <- numeric(numIndustries)
for (i in 1:numIndustries) {
  emp_simple_multipliers[i] <- sum(A_Leontief_Inverse[, i] * employment_coefficients)
}

emp_total_multipliers <- numeric(numIndustries)
for (i in 1:numIndustries) {
  emp_total_multipliers[i] <- sum(B_Star[, i] * employment_coefficients)
}

#
emp_industrial_support_effects <- emp_simple_multipliers - emp_initial_effects - emp_first_round_effects
emp_production_induced_effects <- emp_first_round_effects + emp_industrial_support_effects
emp_consumption_induced_effects <- emp_total_multipliers - emp_simple_multipliers

employment_multipliers <- tibble(
  Industry = colnames(A),
  `Initial effects` = emp_initial_effects,
  `First round effects` = emp_first_round_effects,
  `Industrial support effects` = emp_industrial_support_effects,
  `Production induced effects` = emp_production_induced_effects,
  `Consumption induced effects` = emp_consumption_induced_effects,
  `Simple multipliers` = emp_simple_multipliers,
  `Total multipliers` = emp_total_multipliers
)

write_csv(employment_multipliers,'data/io-employment-multipliers-2022.csv')

