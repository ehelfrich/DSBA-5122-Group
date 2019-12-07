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
library(waiter)
######################## Pre-App ####################################
# Load and reduce DataFrame 

data = read_csv('./data/all_tickets.csv') # correct path for runtime execution

# Filter ticket_type = 1 and drop unused columns
data = data %>%
  filter(ticket_type == 1) %>%
  select(body, category) %>%
  mutate(id = row_number())

# Split off Test Set at app start
test_data = stratified(data, "category", .01)
train_data = data %>%
  anti_join(test_data, by = c("id" = "id"))

# Global Functions
sampleData = function(target_data){
  reduced = stratified(target_data, "category", .10)
  return(reduced)
}

######################## Shiny Server ###############################
shinyServer(function(input, output) { 
  
  #### Data Exploration ####
  data_reduced = eventReactive(input$data_generate, {
    df_train = sampleData(train_data)
    df_test = test_data
    return(list(df_train, df_test))
  }, ignoreNULL = F)
  
  tokenizer = reactive({
    df = data_reduced()
    df_train = df[[1]]
    df_test = df[[1]]
    train_tokens = df_train %>%
      unnest_tokens(output = word, input = body)
    test_tokens = df_test %>%
      unnest_tokens(output = word, input = body)
    return(list(train_tokens, test_tokens))
  })
  
  output$df = DT::renderDataTable({data_reduced()[[1]]})
  
  output$token_summary = renderTable({
    tokens = tokenizer()
    train_tokens = tokens[[1]]
    train_tokens %>%
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
    train_tokens = tokens[[1]]
    train_tokens %>%
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
    train_tokens = tokens[[1]]
    test_tokens = tokens[[2]]
    if(input$stopwords){
      train_tokens = train_tokens %>%
        anti_join(stop_words, by = c("word" = "word"))
      test_tokens = test_tokens %>%
        anti_join(stop_words, by = c("word" = "word"))
    }
    token_drop_train = train_tokens %>%
      group_by(id) %>%
      summarize(num_word = n(), num_char = sum(nchar(word))) %>%
      filter(num_word < input$minwords)
    token_drop_test = train_tokens %>%
      group_by(id) %>%
      summarize(num_word = n(), num_char = sum(nchar(word))) %>%
      filter(num_word < input$minwords)
    
    token_final_train = train_tokens %>%
      anti_join(token_drop_train, by='id')
    token_final_test = train_tokens %>%
      anti_join(token_drop_test, by='id')
    
    return(list(token_final_train, token_final_test))
  })
  
  # DTM Creation
  vectorizerProcessing = reactive({
    token_final = feProcessing()
    token_final_train = token_final[[1]]
    token_final_test = token_final[[2]]
    
    if(input$vectorizeframe == "Count Vectorizer"){
      # Vectroize Count Vector
      dtm_train = token_final_train %>%
        count(id, word, sort = T) %>%
        cast_dtm(document = id, term = word, value = n)
      dtm_test = token_final_test %>%
        count(id, word, sort = T) %>%
        cast_dtm(document = id, term = word, value = n)
    }
    else if(input$vectorizeframe == "TF-IDF") {
      # Vectorize TFIDF Vector
      dtm_train = token_final_train %>%
        count(id, word, sort = T) %>%
        cast_dtm(document = id, term = word, value = n, weighting = tm::weightTfIdf)
      dtm_test = token_final_test %>%
        count(id, word, sort = T) %>%
        cast_dtm(document = id, term = word, value = n, weighting = tm::weightTfIdf)
    }
    else{
      stop("Error: No Vectorizer selected")
    }
    
    return(list(dtm_train, dtm_test))
  })
  
  # Button to run FE and Plots
  observeEvent(input$FE_run, {
    show_waiter(spin_fading_circles())
    tokens = feProcessing()[[1]]
    # dtm = vectorizerProcessing()[[1]]
    
    # Histogram
    output$fe_hist = renderPlot({
      tokens %>%
        count(word, sort = T) %>%
        filter(n > input$m_words) %>%
        ggplot(aes(x = reorder(word, n), y = n)) +
          geom_col() +
          coord_flip() + 
        theme(text = element_text(size=input$sizewords)) +
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
      hide_waiter()
    })
  })
  
  #### Dimensionality Reduction ####
  # Dimentionality Reduction Generation
  gen = reactive({
    dtm = vectorizerProcessing()[[1]]
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
    show_waiter(spin_fading_circles())
    i <- gen()
    hide_waiter()
    return(i)
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
      dtm_train = vectorizerProcessing()[[1]]
      features = feProcessing()[[1]]
      x = features %>% distinct(id, .keep_all = T) %>% select(-word)
      ctrl = trainControl(method = 'cv', number=3, verboseIter = F)
      rf = train(x = as.matrix(dtm_train), y = factor(x$category), method = "ranger", num.trees=input$rf__num_trees, trControl = ctrl)
    return(rf)
  })
  
  # Process Test Set using same FE settings
  test_processing = reactive({
    dtm = vectorizerProcessing()[[2]]
  })
  
  # Action Button ML Run
  ml_action = eventReactive(input$rf_run, {
    show_waiter(spin_fading_circles())
    i <- ml_model()
    hide_waiter()
    return(i)
  })
  
  # Model CM
  output$cm = renderPrint({
    model = ml_action()
    isolate({
    features = feProcessing()[[2]]
    x = features %>% distinct(id, .keep_all = T) %>% select(-word)
    test_data_dtm = test_processing()
    y_pred = predict(model, as.matrix(test_data_dtm))
    #browser()
    conf_matrix = confusionMatrix(y_pred, factor(x$category))
    conf_matrix
    })
  })
  
  # Plot Model
  output$ml_plot = renderPlot({
    model = ml_action()
    #browser()
    plot(model)
  })
})
