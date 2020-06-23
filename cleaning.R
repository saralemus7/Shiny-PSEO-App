library(readxl)
library(tidyverse)
pseo_co <- read_excel("pseo_co.xlsx", skip = 4)
cip_info <- read_csv("label_cipcode.csv")

pseo_co %>% 
  group_by(label_degree_level) %>% 
  select(label_degree_level, label_cipcode)

pseo <- pseo_co %>% 
  filter(agg_level_pseo == 48, status_y1_earnings == "1", status_y5_earnings == "1", status_y10_earnings == "1")

pseo <- pseo %>% 
  mutate(cipcode_twodigit = str_replace_all(pseo$cipcode, pattern = "\\..*", "")) 

cip_2d <- cip_info %>% 
  slice(1:48)

pseo <- pseo %>% 
  left_join(cip_2d, by = c("cipcode_twodigit" = "CIPFamily"))

pseo <- pseo %>% 
  mutate(label = str_replace(label, pattern = "Engineering Technologies and Engineering-Related Fields", replacement = "Engineering"))

saveRDS(pseo, file = "PSEO/data/pseo.rds")