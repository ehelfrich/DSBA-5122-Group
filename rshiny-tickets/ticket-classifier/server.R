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

# Plot Category Colors
cateogry_colors = brewer.pal(12,"Paired")
names(cateogry_colors) = levels(factor(data$category))
color_scale = scale_colour_manual(name = "Category",values = cateogry_colors)
color_fill = scale_fill_manual(name = "Category",values = cateogry_colors)

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
    df_test = df[[2]]
    train_tokens = df_train %>%
      unnest_tokens(output = word, input = body)
    test_tokens = df_test %>%
      unnest_tokens(output = word, input = body)
    return(list(train_tokens, test_tokens))
  })
  
  # Data Table of Training Set
  output$df = DT::renderDataTable({data_reduced()[[1]]})
  
  # Summary Table
  summary_table = reactive({
    tokens = tokenizer()
    train_tokens = tokens[[1]]
    table = train_tokens %>%
      group_by(id) %>%
      summarize(num_word = n(), num_char = sum(nchar(word))) %>% #num_char does not include whitespace
      summarize(average_word_count = mean(num_word),
                train_min_word_count = min(num_word),
                train_max_word_count = max(num_word),
                train_median_word_count = median(num_word),
                train_average_character_count = mean(num_char),
                train_min_character_count = min(num_char),
                train_max_character_count = max(num_char)) %>%
      gather()
    test_tokens = tokens[[2]]
    table1 = test_tokens %>%
      group_by(id) %>%
      summarize(num_word = n(), num_char = sum(nchar(word))) %>% #num_char does not include whitespace
      summarize(average_word_count = mean(num_word),
                test_min_word_count = min(num_word),
                test_max_word_count = max(num_word),
                test_median_word_count = median(num_word),
                test_average_character_count = mean(num_char),
                test_min_character_count = min(num_char),
                test_max_character_count = max(num_char)) %>%
      gather()
    table = bind_rows(table, table1)
    return(table)
  })
  
  # Render Boxes
  output$training_size = renderInfoBox({ # Training Set Size
    infoBox("Size of Training Set", {
      train_tokens = tokenizer()[[1]]
      train_tokens = train_tokens %>% count(n_distinct(id))
      train_tokens[[1]]
    }, color = "green")
  })
  output$training_avg_count = renderInfoBox({ # Training Set Median Word Count
    infoBox("Average Word Count of Training Set", {
      round(summary_table()[[1,2]], 2)
    }, color = "green")
  })
  output$training_median_count = renderInfoBox({ # Training Set Median Word Count
    infoBox("Median Word Count of Training Set", {
      round(summary_table()[[4,2]], 2)
    }, color = "green")
  })
  output$test_size = renderInfoBox({ # Test Set Size
    infoBox("Size of Test Set", {
      test_tokens = tokenizer()[[2]]
      test_tokens = test_tokens %>% count(n_distinct(id))
      test_tokens[[1]]
    }, color = "purple")
  })
  output$test_avg_count = renderInfoBox({ # Test Set Median Word Count
    infoBox("Average Word Count of Test Set", {
      round(summary_table()[[8,2]], 2)
    }, color = "purple")
  })
  output$test_median_count = renderInfoBox({ # Test Set Median Word Count
    infoBox("Median Word Count of Test Set", {
      round(summary_table()[[11,2]], 2)
    }, color = "purple")
  })
  
  # Training Set Distribution Plot
  output$category_dist = renderPlot({  
    tokens = tokenizer()
    train_tokens = tokens[[1]]
    train_tokens %>%
      count(category) %>%
      add_row(category = 2, n = 0, .before = 3) %>% # add in category 2 since it has 0 tickets
      mutate(category = factor(category)) %>%
      ggplot(aes(x=category, y=n, fill = category)) +
      geom_bar(stat = 'identity') +
      color_scale +
      scale_y_log10() +
      labs(y='log(count)', x='category')})
  
  # Download Master Data Set (cleaned)
  
  output$data.csv = downloadHandler(
    filename = function () {
      paste("master_data", ".csv", sep="")
    },
    content = function(file) {
      write.csv(data, file, row.names = F)
    }
  )
  
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
    show_waiter(
      tagList(
        spin_folding_cube(),
        span("Loading ...", style = "color:white;")
      ))
    
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
    show_waiter(
      tagList(
        spin_folding_cube(),
        span("Loading ...", style = "color:white;")
      ))
    i <- gen()
    hide_waiter()
    return(i)
  })
  
  # Plot Dimensionality Reduction
  output$dim_plot = renderPlot({
    dimObj = dim_action()
    isolate(
      if(input$dimmethod == "UMAP") {
        plot_data = as_tibble(dimObj$layout) %>%
          mutate(id = as.numeric(rownames(dimObj$layout))) %>%
          left_join(data, by = c("id" = "id")) %>%
          mutate(category = factor(category)) %>%
          select(V1, V2, id, category)
        ggplot(data=plot_data, aes(x=V1, y=V2, color = category)) +
          geom_point() +
          color_scale
      }
      else if(input$dimmethod == "TSNE") {
        plot_data = feProcessing()[[1]] %>%
          group_by(id) %>%
          summarize(num_word = n()) %>% 
          mutate(V1 = dimObj$Y[,1], V2 = dimObj$Y[,2]) %>% 
          left_join(data, by = c("id" = "id")) %>%
          mutate(category = factor(category)) %>%
          select(V1, V2, id, category)
        ggplot(data=plot_data, aes(x=V1, y=V2, color = category)) +
          geom_point() +
          color_scale
      }
    )
  })
  
  # Bars Chart
  output$bars = renderPlot({
    dimObj = dim_action()
    if(input$dimmethod == "UMAP") {
      plot_data = as_tibble(dimObj$layout) %>%
        mutate(id = as.numeric(rownames(dimObj$layout))) %>%
        left_join(data, by = c("id" = "id")) %>%
        mutate(category = factor(category)) %>%
        select(V1, V2, id, category)
      i = brushedPoints(plot_data, input$dim_plot_brush)
      if(nrow(i) == 0) {
        i = plot_data
      }
      i %>%
        count(category) %>%
        ggplot(aes(x = category, y = n, fill = category)) +
        geom_col(width = .1) +
        labs(x="Category", y = "Count of Tickets") +
        theme(legend.key.size = unit(4,"mm")) +
        color_fill
    }
    else if(input$dimmethod == "TSNE") {
      j = feProcessing()
      plot_data = feProcessing()[[1]] %>%
        group_by(id) %>%
        summarize(num_word = n()) %>% 
        mutate(V1 = dimObj$Y[,1], V2 = dimObj$Y[,2]) %>% 
        left_join(data, by = c("id" = "id")) %>%
        mutate(category = factor(category)) %>%
        select(V1, V2, id, category)
      i = brushedPoints(plot_data, input$dim_plot_brush)
      if(nrow(i) == 0) {
        i = plot_data
      }
      i %>%
        count(category) %>%
        ggplot(aes(x = category, y = n, fill = category)) +
        geom_col(width = .1) +
        labs(x="Category", y = "Count of Tickets") +
        theme(legend.key.size = unit(4,"mm")) +
        color_fill
    }
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
    show_waiter(
      tagList(
        spin_folding_cube(),
        span("Loading ...", style = "color:white;")
      ))
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
    conf_matrix = confusionMatrix(y_pred, factor(x$category))
    conf_matrix
    })
  })
  
  # Plot Model
  output$ml_plot = renderPlot({
    model = ml_action()
    plot(model)
  })
  
  # Save Model to rds File
  output$savedmodel.rds = downloadHandler(filename = paste("saved_model", ".rds", sep=""), 
                                          content = function(file) {
                                            saveRDS(ml_action(), file)
                                          }
                          )
})
