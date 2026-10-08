library(tidyverse)
library(tidytext)
library(wordcloud)
library(RColorBrewer)
library(cluster)

# 1. Load and clean movie data

movies <- read_csv("movies_raw.csv", show_col_types = FALSE)

# Remove duplicate movie IDs and empty movie overviews.
movies <- movies |>
  distinct(id, .keep_all = TRUE) |>
  filter(!is.na(overview), str_trim(overview) != "")

cat("Number of movies after cleaning:", nrow(movies), "\n")

# 2. Text cleaning and tokenisation

movie_words <- movies |>
  select(id, title, overview) |>
  mutate(
    overview = str_to_lower(overview),
    overview = str_replace_all(overview, "[^a-zA-Z ]", " "),
    overview = str_squish(overview)
  ) |>
  unnest_tokens(word, overview) |>
  filter(str_length(word) > 2) |>
  anti_join(stop_words, by = "word")

# Remove a small number of very common generic words that do not help
# distinguish movie content.
generic_words <- c("movie", "film")

movie_words <- movie_words |>
  filter(!word %in% generic_words)

# 3. Most frequent words

word_frequency <- movie_words |>
  count(word, sort = TRUE)

print(head(word_frequency, 20))

# Save frequency table
write_csv(word_frequency, "word_frequency.csv")

# 4. Text visualisation 1 - Most frequent words

top_words <- word_frequency |>
  slice_max(n, n = 20) |>
  mutate(word = fct_reorder(word, n))

ggplot(top_words, aes(x = n, y = word)) +
  geom_col() +
  labs(
    title = "Top 20 Most Frequent Words in Movie Overviews",
    x = "Frequency",
    y = "Word"
  ) +
  theme_minimal()

# Save plot
ggsave(
  "text_top_words.png",
  width = 8,
  height = 6,
  dpi = 300
)

# 5. Text visualisation 2 - Word cloud

set.seed(42)

png("text_wordcloud.png", width = 1000, height = 800)
wordcloud(
  words = word_frequency$word[1:60],
  freq = word_frequency$n[1:60],
  min.freq = 1,
  max.words = 60,
  random.order = FALSE,
  scale = c(4, 0.7),
  colors = brewer.pal(8, "Dark2")
)
dev.off()

# 6. Create TF-IDF representation for clustering

# TF-IDF gives more weight to words that are important in a movie overview
# but less common across the whole dataset.

tfidf_data <- movie_words |>
  count(id, word) |>
  bind_tf_idf(word, id, n)

# Remove extremely rare words. This reduces noise in the clustering.
tfidf_data <- tfidf_data |>
  group_by(word) |>
  filter(n() >= 3) |>
  ungroup()

# Create movie x word matrix.
tfidf_wide <- tfidf_data |>
  select(id, word, tf_idf) |>
  pivot_wider(
    names_from = word,
    values_from = tf_idf,
    values_fill = 0
  )

tfidf_matrix <- tfidf_wide |>
  select(-id) |>
  as.matrix()

# 7. Cosine distance

# Movie overviews are represented by TF-IDF vectors.
# Cosine distance is suitable because it compares the direction of
# the text vectors, rather than mainly their length.

row_norms <- sqrt(rowSums(tfidf_matrix^2))
row_norms[row_norms == 0] <- 1

normalised_matrix <- tfidf_matrix / row_norms

cosine_similarity <- normalised_matrix %*% t(normalised_matrix)
cosine_distance <- as.dist(1 - cosine_similarity)

# 8. Choose the number of clusters using silhouette score

k_values <- 2:8
silhouette_scores <- numeric(length(k_values))

for (i in seq_along(k_values)) {
  k <- k_values[i]
  model <- pam(cosine_distance, k = k, diss = TRUE)
  silhouette_scores[i] <- model$silinfo$avg.width
}

k_results <- tibble(
  k = k_values,
  silhouette_score = silhouette_scores
)

print(k_results)
write_csv(k_results, "cluster_k_results.csv")

best_k <- k_results |>
  slice_max(silhouette_score, n = 1, with_ties = FALSE) |>
  pull(k)

cat("Selected number of clusters:", best_k, "\n")

# Visualise silhouette scores

ggplot(k_results, aes(x = k, y = silhouette_score)) +
  geom_line() +
  geom_point(size = 3) +
  labs(
    title = "Choosing the Number of Clusters",
    x = "Number of clusters (k)",
    y = "Average silhouette score"
  ) +
  theme_minimal()

ggsave(
  "cluster_silhouette.png",
  width = 8,
  height = 6,
  dpi = 300
)

# 9. Final clustering 

final_model <- pam(cosine_distance, k = best_k, diss = TRUE)

cluster_results <- movies |>
  select(id, title) |>
  mutate(cluster = final_model$clustering)

write_csv(cluster_results, "movie_clusters.csv")

# 10. 2D visualisation using classical MDS

mds <- cmdscale(cosine_distance, k = 2, eig = TRUE)

cluster_plot_data <- cluster_results |>
  mutate(
    MDS1 = mds$points[, 1],
    MDS2 = mds$points[, 2],
    cluster = factor(cluster)
  )

ggplot(cluster_plot_data, aes(x = MDS1, y = MDS2, colour = cluster)) +
  geom_point(alpha = 0.7, size = 2) +
  labs(
    title = paste("Movie Clusters Based on Overview Text (k =", best_k, ")"),
    x = "MDS Dimension 1",
    y = "MDS Dimension 2",
    colour = "Cluster"
  ) +
  theme_minimal()

ggsave(
  "movie_clusters_mds.png",
  width = 8,
  height = 6,
  dpi = 300
)

# 11. Find important words in each cluster

cluster_lookup <- tibble(
  id = tfidf_wide$id,
  cluster = final_model$clustering
)

cluster_terms <- tfidf_data |>
  left_join(cluster_lookup, by = "id") |>
  group_by(cluster, word) |>
  summarise(mean_tfidf = mean(tf_idf), .groups = "drop") |>
  group_by(cluster) |>
  slice_max(mean_tfidf, n = 15, with_ties = FALSE) |>
  arrange(cluster, desc(mean_tfidf))

print(cluster_terms)
write_csv(cluster_terms, "cluster_top_words.csv")

# 12. Cluster sizes

cluster_sizes <- cluster_results |>
  count(cluster, name = "movie_count") |>
  arrange(cluster)

print(cluster_sizes)
write_csv(cluster_sizes, "cluster_sizes.csv")

# End

cat("\nText analysis and clustering completed.\n")
