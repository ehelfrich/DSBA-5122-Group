

# UI

## Overall Design

NavBar going over the top of the webpage with each tab.  The tabs will break down the workflow of the ML problem.


## Problem Tab

This will detail the problem we are trying to resolve.

## Data Exploration

This will show the raw data and were we got it.
- Show sample of the dataframe
- Show some summary stats (avg word count, avg character count)
- Distrbution of labels (category) - where ticket_type=1 (bar graph)

## Feature Engineering
- Remove stop words (toggle button)
	- ability to add custom stop words
	- word cloud or histogram
		- Sliders to change how many words it is looking
		- sliders to adjust ranges
- ability to specify minimum word count
	- slider bar to choose minmum word count

- For each of these changes give the user a button to see how it affects the visuals (cloud or historgram/# of labels in each category) 

- vecorize the dataframe
	- choose either TF-IDF or count vectorizer

## Dimenstionality Reduction
- UMAP or TSNE (drop down)
- Show the data under going dimensionality reduction (UMAP)
- Show the data on an interactive graph that lets you select data area
- Show bars of the categories on the side of the data (x,y)
- ability to brush

## ML solutions
- Choose between logistic regression or Random Forest (drop down)
- widgets for the hyper parameters
- boxes showing test tickets with their labels/predicted label (button to randomly choose)
	- extra: ability to type in a sample ticket and see what the label would be?
- Show confusion matrix with precision/recall/f1 scores for each of the labels

- Export data/model - include findings
