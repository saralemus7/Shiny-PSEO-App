library(readxl)
library(tidyverse)
pseo_co <- read_excel("~/Downloads/pseo_co.xlsx", skip = 4)
cip_info <- read_csv("~/Downloads/label_cipcode.csv")

pseo_co %>% 
  group_by(label_degree_level) %>% 
  select(label_degree_level, label_cipcode)