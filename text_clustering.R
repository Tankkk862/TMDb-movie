library(tidyverse)
library(tidytext)
library(wordcloud)
library(RColorBrewer)
library(cluster)

# 1. Load and clean movie data

# Locate the dataset even if RStudio starts one folder above the project.
csv_candidates <- c(
  "movies_raw.csv",
  file.path("TMDb-movie-main", "movies_raw.csv")
)
csv_found <- csv_candidates[file.exists(csv_candidates)]
if (length(csv_found) == 0) {
  stop(paste0(
    "Cannot find movies_raw.csv. Current folder: ", getwd(),
    ". Open the folder containing movies_raw.csv in RStudio."
  ))
}
# Save all results beside the dataset.
project_dir <- dirname(normalizePath(csv_found[1], winslash = "/"))
setwd(project_dir)
cat("Project folder:", getwd(), "\n")
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
# and less common across the whole dataset.

tfidf_data <- movie_words |>
  count(id, word) |>
  bind_tf_idf(word, id, n)

# Keep all words here. Filtering out rare words can remove every word
# from some movie overviews, making the movie disappear from clustering.

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

# Preserve the movie IDs in the exact order of the TF-IDF matrix.
rownames(tfidf_matrix) <- as.character(tfidf_wide$id)
stopifnot(nrow(tfidf_matrix) == nrow(tfidf_wide))
cat("Movies included in TF-IDF:", nrow(tfidf_matrix), "\n")

# 7. Cosine distance

row_norms <- sqrt(rowSums(tfidf_matrix^2))
if (any(row_norms == 0)) {
  stop("Some movie TF-IDF vectors are empty. Check overview tokenisation.")
}

# Plain tfidf_matrix / row_norms would recycle values by column in R.
normalised_matrix <- sweep(tfidf_matrix, 1, row_norms, FUN = "/")

cosine_similarity <- normalised_matrix %*% t(normalised_matrix)
cosine_distance_matrix <- 1 - cosine_similarity
cosine_distance_matrix[cosine_distance_matrix < 0] <- 0
cosine_distance_matrix[cosine_distance_matrix > 2] <- 2
diag(cosine_distance_matrix) <- 0
stopifnot(is.matrix(cosine_distance_matrix),
          nrow(cosine_distance_matrix) == nrow(tfidf_matrix),
          ncol(cosine_distance_matrix) == nrow(tfidf_matrix),
          all(is.finite(cosine_distance_matrix)))
cosine_distance <- stats::as.dist(cosine_distance_matrix)
stopifnot(inherits(cosine_distance, "dist"),
          attr(cosine_distance, "Size") == nrow(tfidf_matrix))
cat("Cosine distance created for", attr(cosine_distance, "Size"), "movies.\n")

set.seed(42)

# 8. Choose the number of clusters using silhouette score

k_values <- 2:min(8, nrow(tfidf_matrix) - 1)
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

# PAM returns clusters in the same row order as tfidf_matrix.
# Match by movie ID 
stopifnot(length(final_model$clustering) == nrow(tfidf_matrix))
cluster_results <- tibble(
  id = tfidf_wide$id,
  cluster = as.integer(final_model$clustering)
) |>
  left_join(movies |> select(id, title), by = "id") |>
  select(id, title, cluster)

stopifnot(nrow(cluster_results) == nrow(tfidf_matrix))
cat("Movies assigned to clusters:", nrow(cluster_results), "\n")

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

cluster_lookup <- cluster_results |>
  select(id, cluster)

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
