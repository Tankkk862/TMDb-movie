# COMP3020 Social Web Analytics
# TMDb Movie Data Collection
# Person 1 - Data Collection and Hypothesis Testing

library(httr2)

# --------------------------------------------------
# 1. TMDb API setup
# --------------------------------------------------

api_key <- "YOUR_API_KEY"

# --------------------------------------------------
# 2. Collect movie data
# --------------------------------------------------

all_movies <- list()

for (page in 1:25) {
  
  url <- paste0(
    "https://api.themoviedb.org/3/discover/movie?api_key=",
    api_key,
    "&page=", page
  )
  
  response <- request(url) |>
    req_perform() |>
    resp_body_json()
  
  page_movies <- data.frame(
    id = sapply(response$results, function(x) x$id),
    title = sapply(response$results, function(x) x$title),
    overview = sapply(response$results, function(x) x$overview),
    release_date = sapply(response$results, function(x) x$release_date),
    popularity = sapply(response$results, function(x) x$popularity),
    vote_average = sapply(response$results, function(x) x$vote_average),
    vote_count = sapply(response$results, function(x) x$vote_count),
    genre_ids = sapply(
      response$results,
      function(x) paste(x$genre_ids, collapse = ",")
    )
  )
  
  all_movies[[page]] <- page_movies
}

movies <- do.call(rbind, all_movies)

# --------------------------------------------------
# 3. Clean movie data
# --------------------------------------------------

movies <- movies[!duplicated(movies$id), ]

movies <- movies[nchar(movies$overview) > 0, ]

# Check final dataset
dim(movies)

# Save movie data
write.csv(
  movies,
  "movies_raw.csv",
  row.names = FALSE
)

# --------------------------------------------------
# 4. Collect network data
# --------------------------------------------------

network_data <- list()

for (i in 1:nrow(movies)) {
  
  movie_id <- movies$id[i]
  
  url <- paste0(
    "https://api.themoviedb.org/3/movie/",
    movie_id,
    "?api_key=", api_key,
    "&append_to_response=credits"
  )
  
  movie_detail <- request(url) |>
    req_perform() |>
    resp_body_json()
  
  # Actors
  actors <- movie_detail$credits$cast
  
  if (is.null(actors)) {
    actors <- list()
  } else {
    actors <- head(actors, 10)
  }
  
  if (length(actors) == 0) {
    
    actor_edges <- data.frame(
      movie_id = integer(0),
      person_id = integer(0),
      person_name = character(0),
      relationship = character(0)
    )
    
  } else {
    
    actor_edges <- data.frame(
      movie_id = rep(movie_id, length(actors)),
      person_id = sapply(actors, function(x) x$id),
      person_name = sapply(actors, function(x) x$name),
      relationship = rep("actor", length(actors))
    )
  }
  
  # Directors
  crew <- movie_detail$credits$crew
  
  if (is.null(crew)) {
    crew <- list()
  }
  
  directors <- Filter(
    function(x) {
      !is.null(x$job) &&
        is.character(x$job) &&
        length(x$job) > 0 &&
        x$job == "Director"
    },
    crew
  )
  
  if (length(directors) > 0) {
    
    director_edges <- data.frame(
      movie_id = rep(movie_id, length(directors)),
      person_id = sapply(directors, function(x) x$id),
      person_name = sapply(directors, function(x) x$name),
      relationship = rep("director", length(directors))
    )
    
  } else {
    
    director_edges <- data.frame(
      movie_id = integer(0),
      person_id = integer(0),
      person_name = character(0),
      relationship = character(0)
    )
  }
  
  network_data[[i]] <- rbind(
    actor_edges,
    director_edges
  )
}

network_edges <- do.call(rbind, network_data)

# Check network data
dim(network_edges)

# Save network data
write.csv(
  network_edges,
  "network_edges.csv",
  row.names = FALSE
)