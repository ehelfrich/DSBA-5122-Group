library(tidyverse)
library(tidytext)
library(stringr)
library(caret)
library(tm)
library(wordcloud)
library(RColorBrewer)

raw = read_csv('./ticket-classifier/data/filtered_data_1.csv')
raw = raw %>%
  select(-X1)

tokens = read_csv('./ticket-classifier/data/tokens.csv')
tokens = tokens %>%
  select(-X1)

### Data Exploration ###  

# Show Sample DataFrame
head(raw)

# Show Summary Stats
token_summary = tokens %>%
  group_by(id) %>%
  summarize(num_word = n(), num_char = sum(nchar(word))) #num_char does not include whitespace
  
# Plot Distribution of Labels
raw %>%
  count(category) %>%
  add_row(category = 2, n = 0, .before = 3) %>% # add in category 2 since it has 0 tickets
  ggplot(aes(x=factor(category), y=n)) +
  geom_bar(stat = 'identity') +
  scale_y_log10() +
  labs(y='log(count)', x='category')

### Feature Engineering ###

# Remove Stop Words

token_stop = tokens %>%
  anti_join(stop_words, by = c("word" = "word"))

# Word Histogram
token_stop %>%
  count(word, sort = T) %>%
  filter(n>3000) %>%
  ggplot(aes(x = reorder(word, n), y = n)) +
  geom_col() +
  coord_flip() + 
  labs(x='', y='')

# Word Cloud
token_stop %>%
  count(word, sort = TRUE) %>%
  with(
    wordcloud(
      word, 
      n,
      scale = c(8, .3),
      random.order = FALSE, 
      max.words = 50, 
      colors=brewer.pal(8,"Dark2")
    )
  )

# Specify Minimum Word Count
token_drop = token_stop %>%
  group_by(id) %>%
  summarize(num_word = n(), num_char = sum(nchar(word))) %>%
  filter(num_word < 10)

token_final = token_stop %>%
  anti_join(token_drop, by='id')

# Vectroize Count Vector
token_dtm = token_final %>%
  count(id, word, sort = T) %>%
  cast_dtm(document = id, term = word, value = n)
  
# Vectorize TFIDF Vector
token_dtm_idf = token_final %>%
  count(id, word, sort = T) %>%
  cast_dtm(document = id, term = word, value = n, weighting = tm::weightTfIdf)

### Dimensionality Reduction ###

# UMAP

# SVD/TSNE

# Plot Dimensinality Reduction

### ML Solutions ###

# Choose algorithm

# Logistic Regression

# Random Forest