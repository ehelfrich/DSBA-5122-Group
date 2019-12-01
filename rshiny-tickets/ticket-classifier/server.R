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
  
})
