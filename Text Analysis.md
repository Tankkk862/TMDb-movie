## 1. Text analysis

### Method

The overview was used for text analysis because of the movie's description. Duplicate movies and empty overview were removed before the analysis begin. The text was converted to lowercase and punctuation has been removed. 

### Frequent words

A word frequency table was created to identify the most common words in movie descriptions. A chart of the top 20 words and a word cloud were used as the two visualisations.

### Interpretation

The frequent words show recurring themes in the movies table, including every storrytelling factors.

Not interpreting word frequency as the number of movies in a genre. A word can appear multiple times and can be used in different types of movies.

## 2. Clustering

### Research aim

The aim was to identify groups of movies with similar content based on their overview descriptions.

### Text representation

TF-IDF was used to convert every movie overview into a numerical vector. TF-IDF highlight the words that are useful for distinguishing one movie description from another and lower the importance to words that appear in heaps of descriptions.

### Similarity

Cosine distance was selected because the data consists of text vectors. It compares the direction of two vectors, so it focuses on every letter of the words rather than simply the length of an overview.

### Choosing k

The average silhouette score was calculated for k values from 2 to 8. The k with the highest average silhouette score was selected for the final PAM clustering model.

### Important interpretation note

If the best silhouette score is close to zero, the clusters should be described as weakly separated rather than as clear cut movie genres.
### Cluster interpretation

We Using movies table to identify the most important words in each cluster. 

