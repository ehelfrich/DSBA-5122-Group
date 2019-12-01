library(tidyverse)
library(tidytext)
library(stringr)
library(caret)
library(tm)
library(wordcloud)
library(RColorBrewer)
library(umap)
library(splitstackshape)

set.seed(100)

# raw = read_csv('./ticket-classifier/data/filtered_data_1.csv')
# raw = raw %>%
#   select(-X1)
# 
# tokens = read_csv('./ticket-classifier/data/tokens.csv')
# tokens = tokens %>%
#   select(-X1)

# Load and reduce DataFrame 

#set.seed(99)

data = read_csv('./rshiny-tickets/ticket-classifier/data/all_tickets.csv')

# Filter ticket_type = 1 and drop unused columns
raw_reduced = data %>%
  filter(ticket_type == 1) %>%
  select(body, category) %>%
  mutate(id = row_number()) %>%
  stratified("category", .1)

tokens <- raw_reduced %>%
  unnest_tokens(output = word, input = body)
### Data Exploration ###  

# Show Sample DataFrame
head(raw)

# Show Summary Stats
token_summary = tokens %>%
  group_by(id) %>%
  summarize(num_word = n(), num_char = sum(nchar(word))) %>% #num_char does not include whitespace
  summarize(average_word_count = mean(num_word),
            min_word_count = min(num_word),
            max_word_count = max(num_word),
            average_character_count = mean(num_char),
            min_character_count = min(num_char),
            max_character_count = max(num_char)) %>%
  gather()
token_summary

# Plot Distribution of Labels

raw %>%
  count(category) %>%
  add_row(category = 2, n = 0, .before = 3) %>% # add in category 2 since it has 0 tickets
  ggplot(aes(x=factor(category), y=n)) +
  geom_bar(stat = 'identity') +
  scale_y_log10() +
  labs(y='log(count)', x='category')

raw_reduced %>%
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
  filter(n>1000) %>%
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

# Test-Train Split here (70-30)


# Sparse Matrix
token_sparse = token_final %>%
  count(id, word, sort = T)  %>%
  cast_sparse(id, word, n)

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

idf_matrix = token_dtm_idf %>%
  cast_sparse(document, term, count)

idf_umap = umap(as.matrix(token_dtm_idf))

ggplot(data=as_tibble(idf_umap$layout), aes(x=V1, y=V2)) +
  geom_point()

# PCA/TSNE

pca = prcomp(token_dtm_idf, scale.=T)
pca50 = pca$rotation[,1:50]
library(Rtsne)
tsne50 = Rtsne(pca50, dims=2, perplexity=50, check_duplicates = F)

ggplot(data=as_tibble(tsne50$Y), aes(x=V1, y=V2)) +
  geom_point()

### ML Solutions ###

# Choose algorithm

# Logistic Regression

x = token_final %>% distinct(id, .keep_all = T) %>% select(-word)

logreg = train(x = token_dtm_idf, y = factor(x$category), method = "svmLinear3", family="multinomial")

logreg = glmnet(as.matrix(token_dtm_idf), factor(x$category), family="multinomial")

# Random Forest

x = token_final %>% distinct(id, .keep_all = T) %>% select(-word)

rf = train(x = as.matrix(token_dtm_idf), y = factor(x$category), method = "ranger", num.trees=10, trControl = trainControl(method = "oob"))


# Text2Vec
library(text2vec)

prep_fun = tolower
tok_fun = word_tokenizer
# 
it_token = itoken(raw_reduced$body, preprocessor = prep_fun, tokenizer = tok_fun, ids = raw_reduced$id, progressbar = T)
# tokens = raw_reduced$body %>%
#   prep_fun %>%
#   tok_fun
# it_token = itoken(tokens, ids = raw_reduced$id, progressbar = T)
vocab = create_vocabulary(it_token)

vectorizer = vocab_vectorizer(vocab)
dtm_train = create_dtm(it_token, vectorizer)

identical(rownames(dtm_train), as.character(raw_reduced$id)) # Test to see if rownames match

rf = train(x = as.matrix(dtm_train), y = factor(raw_reduced$category), method = "ranger", num.trees=10, trControl = trainControl(method = "oob"))

logreg = glmnet(dtm_train, factor(raw_reduced$category), family="multinomial")

