#install.packages("usmap")
library(usmap)
library(ggplot2)
library(tidyverse)
library(readxl)
library(lubridate)

df <- read_excel("~/Desktop/us_avg_tuition.xlsx")
#Tidying data according to post
mydata <- gather(df, key = Year, value = Tuition, -State)
glimpse(mydata)
#Getting Just the year according to post
mydata <- mydata %>% 
  mutate(Year = str_sub(Year, start = 1, end = 4))
glimpse(mydata)
#Calculating mean tuition fo state
#Save mydata1 object variable dataset to my local desktop using Rstudio files 
mydata1 <-mydata %>% 
  select(State, Tuition) %>% 
  group_by(State) %>% 
  summarise(Mean_State = mean(Tuition)) %>% 
  arrange(desc(Mean_State))
glimpse(mydata1)
#Read new excel file with the fips codes so I can use the package usmaps
mydata2 <- read_excel("~/Desktop/mydata1.xlsx")
glimpse(mydata2)
plot_usmap(data = mydata2, values = "Mean_State", color = "red") + 
  scale_fill_continuous(
    low = "white", high = "red", name = "Avg_Tuition", label = scales::comma
  ) + theme(legend.position = "right")


