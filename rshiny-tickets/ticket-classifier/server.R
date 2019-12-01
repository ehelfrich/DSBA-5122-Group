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
  
})
