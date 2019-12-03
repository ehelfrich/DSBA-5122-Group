#### Required Libraries ####
library(tidyverse)
library(tidytext)
library(stringr)
library(caret)
library(tm)
library(wordcloud)
library(RColorBrewer)
library(umap)
library(splitstackshape)
library(DT)
library(Rtsne)
library(plotly)
library(glmnet)

######################## Pre-App ####################################
# Load and reduce DataFrame 

data = read_csv('./data/all_tickets.csv') # correct path for runtime execution

# Filter ticket_type = 1 and drop unused columns
data = data %>%
  filter(ticket_type == 1) %>%
  select(body, category) %>%
  mutate(id = row_number())

# Global Functions
sampleData = function(){
  reduced = stratified(data, "category", .1)
  return(reduced)
}



######################## Shiny Server ###############################
shinyServer(function(input, output) { 
  
  #### Data Exploration ####
  data_reduced = eventReactive(input$data_generate, {
    df = sampleData()
    return(df)
  })
  
  tokenizer = reactive({
    df = data_reduced()
    my_tokens = df %>%
      unnest_tokens(output = word, input = body)
    return(my_tokens)
  })
  
  output$df = DT::renderDataTable({data_reduced()})
  
  output$token_summary = renderTable({
    tokens = tokenizer()
    tokens %>%
      group_by(id) %>%
      summarize(num_word = n(), num_char = sum(nchar(word))) %>% #num_char does not include whitespace
      summarize(average_word_count = mean(num_word),
                min_word_count = min(num_word),
                max_word_count = max(num_word),
                median_word_count = median(num_word),
                average_character_count = mean(num_char),
                min_character_count = min(num_char),
                max_character_count = max(num_char)) %>%
      gather()
  })
  
  output$category_dist = renderPlot({  
    tokens = tokenizer()
      tokens %>%
      count(category) %>%
      add_row(category = 2, n = 0, .before = 3) %>% # add in category 2 since it has 0 tickets
      ggplot(aes(x=factor(category), y=n)) +
      geom_bar(stat = 'identity') +
      scale_y_log10() +
      labs(y='log(count)', x='category')})
  
  #### Feature Engineering ####
  
  # Feature Engineering
  feProcessing = reactive({
 
    tokens = tokenizer()
    if(input$stopwords){
      tokens = tokens %>%
        anti_join(stop_words, by = c("word" = "word"))
    }
    token_drop = tokens %>%
      group_by(id) %>%
      summarize(num_word = n(), num_char = sum(nchar(word))) %>%
      filter(num_word < input$minwords)
    
    token_final = tokens %>%
      anti_join(token_drop, by='id')
    
    return(token_final)
  })
  
  # DTM Creation
  vectorizerProcessing = reactive({
    token_final = feProcessing()
    
    if(input$vectorizeframe == "Count Vectorizer"){
      # Vectroize Count Vector
      dtm = token_final %>%
        count(id, word, sort = T) %>%
        cast_dtm(document = id, term = word, value = n)
    }
    else if(input$vectorizeframe == "TF-IDF") {
      # Vectorize TFIDF Vector
      dtm = token_final %>%
        count(id, word, sort = T) %>%
        cast_dtm(document = id, term = word, value = n, weighting = tm::weightTfIdf)
    }
    else{
      stop("Error: No Vectorizer selected")
    }
    
    return(dtm)
  })
  
  # Button to run FE and Plots
  observeEvent(input$FE_run, {
    tokens = feProcessing()
    dtm = vectorizerProcessing()
    
    # Histogram
    output$fe_hist = renderPlot({
      tokens %>%
        count(word, sort = T) %>%
        ggplot(aes(x = reorder(word, n), y = n)) +
          geom_col() +
          coord_flip() + 
          labs(x='', y='')
    })
    
    # Word Cloud
    output$fe_cloud = renderPlot({
      tokens %>%
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
    })
  })
  
  #### Dimensionality Reduction ####
  # Dimentionality Reduction Generation
  gen = reactive({
    dtm = vectorizerProcessing()
    # UMAP
    if(input$dimmethod == "UMAP") { 
      custom.config = umap.defaults
      custom.config$n_neighbors = input$umap__n_neighbors
      custom.config$min_dist = input$umap__min_dist
      umapObj = umap(as.matrix(dtm), custom.config)
      return(umapObj)
    }
    # PCA/T-SNE
    else if(input$dimmethod == "TSNE") {
      tsneX = Rtsne(as.matrix(dtm), dims=2, initial_dims=input$pca__n_dims, perplexity=input$pca__perplexity, check_duplicates = F)
      return(tsneX)
    }
  })
  
  # Action Button Dim Reduction
  dim_action = eventReactive(input$umap_run, {
    gen()
  })
  
  # Plot Dimensionality Reduction
  output$dim_plot = renderPlot({
    dimObj = dim_action()
    isolate(
      if(input$dimmethod == "UMAP") {
        ggplot(data=as_tibble(dimObj$layout), aes(x=V1, y=V2)) +
          geom_point()
      }
      else if(input$dimmethod == "TSNE") {
        ggplot(data=as_tibble(dimObj$Y), aes(x=V1, y=V2)) +
          geom_point()
      }
    )
  })
  
  #### Machine Learning ####
  # Model Run
  ml_model = reactive({
    isolate({
      dtm = vectorizerProcessing()
      features = feProcessing()
      x = features %>% distinct(id, .keep_all = T) %>% select(-word)
      ctrl = trainControl(method = 'cv', number=3, verboseIter = T)
      rf = train(x = as.matrix(dtm), y = factor(x$category), method = "ranger", num.trees=input$rf__num_trees, trControl = ctrl)
    })
    return(rf)
  })
  
  # Action Button ML Run
  ml_action = observeEvent(input$rf_run, {
    ml_model()
  })
  
  # Model Metrics
  output$metrics = renderText({
  model = ml_model()
  print(model)
  })
})
