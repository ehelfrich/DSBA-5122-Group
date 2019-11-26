# Tidy the dataset and produce tidy csv
library(tidyverse)
library(tidytext)
library(stringr)
library(caret)
library(tm)


data = read_csv('./rshiny-tickets/ticket-classifier/data/all_tickets.csv')

# Filter ticket_type = 1 and drop unused columns
data_tt_1 = data %>%
  filter(ticket_type == 1) %>%
  select(body, category) %>%
  mutate(id = row_number())

# create tokens in a tidy dataframe format
ticket_tokens <- data_tt_1 %>%
    unnest_tokens(output = word, input = body)

# Output tidyDF of tokens for future stopword/word stemmer removal
write.csv(ticket_tokens, file='./rshiny-tickets/ticket-classifier/data/tokens.csv')

# Output raw data minus the unused coulumns and filtered
write.csv(data_tt_1, file='./rshiny-tickets/ticket-classifier/data/filtered_data_1.csv')
