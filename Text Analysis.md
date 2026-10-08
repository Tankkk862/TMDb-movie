## 1. Text analysis

### Method

The `overview` field was used for text analysis because it contains the movie descriptions. Duplicate movie IDs and empty overviews were removed before analysis. The text was converted to lowercase, punctuation was removed, and the descriptions were tokenised into individual words. English stopwords were removed, together with the generic words `movie` and `film`.

### Frequent words

A word-frequency table was created to identify the most common words across movie descriptions. A bar chart of the top 20 words and a word cloud were used as the two visualisations.

### Interpretation

The frequent words show recurring themes in the dataset, including characters, relationships, conflict, family, journeys, missions and threats. This suggests that the movie descriptions commonly focus on characters facing a problem or challenge and taking action to resolve it.

Do not interpret word frequency as the number of movies in a genre. A word can appear multiple times and can be used across different types of movies.

## 2. Clustering

### Research aim

The aim was to identify groups of movies with similar content based on their overview descriptions.

### Text representation

TF-IDF was used to convert each movie overview into a numerical vector. TF-IDF gives higher importance to words that are useful for distinguishing one movie description from another and lower importance to words that occur across many descriptions.

### Similarity / distance

Cosine distance was selected because the data consists of text vectors. It compares the direction of two vectors, so it focuses on the pattern of words rather than simply the length of an overview.

### Choosing k

The average silhouette score was calculated for k values from 2 to 8. The k with the highest average silhouette score was selected for the final PAM clustering model.

### Important interpretation note

If the best silhouette score is close to zero, the clusters should be described as weakly separated rather than as clear-cut movie genres. This is important for this dataset because movie overviews often contain broad words and overlapping themes.

### Cluster interpretation

Use `cluster_top_words.csv` to identify the most important words in each cluster. Use these words together with a few example movie titles from `movie_clusters.csv` to describe each cluster.

A safe wording is:

> Cluster X is mainly characterised by words related to [themes]. Example movies include [examples]. This suggests that the cluster represents movies with similar content themes rather than a strict genre category.

## 3. Short methodology paragraph

> We analysed the movie overview text using tokenisation, stopword removal and word-frequency analysis. TF-IDF was then used to represent each movie as a numerical text vector. Cosine distance was selected to compare the movie descriptions, and PAM clustering was performed. The number of clusters was selected by comparing average silhouette scores for k = 2 to 8. The resulting clusters were visualised using classical multidimensional scaling (MDS) and interpreted using their highest TF-IDF words.

## 4. Short conclusion paragraph

> The text analysis shows that the movie descriptions contain recurring themes such as characters, family, conflict, missions and journeys. The clustering analysis groups movies with similar vocabulary and content patterns. However, the clusters should not automatically be treated as formal genres, especially if the silhouette score is low, because many movie descriptions share common themes.
