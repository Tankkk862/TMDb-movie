# COMP3020 Social Web Analytics – TMDb Movie Analysis

## Project Overview

This project analyses movie data collected from **The Movie Database (TMDb) API** using R.

The dataset is used for:

* Text/content analysis
* Hypothesis testing
* Clustering
* Network analysis

## Data Collection

Movie data was collected using the TMDb API.

We collected **500 movie records** and selected the following variables:

* `id` – Movie ID
* `title` – Movie title
* `overview` – Movie description
* `release_date` – Release date
* `popularity` – TMDb popularity score
* `vote_average` – Average user rating
* `vote_count` – Number of votes
* `genre_ids` – TMDb genre IDs

After cleaning duplicate movie IDs and movies with empty overviews, the final dataset contains **494 movies**.

## Network Data

Movie credits were collected from the TMDb API using the movie credits endpoint.

The network dataset contains **5,438 movie–person relationships**.

Each edge contains:

* `movie_id` – Movie ID
* `person_id` – Person ID
* `person_name` – Actor or director name
* `relationship` – `actor` or `director`

The network data uses relationships between movies and their actors/directors.

## Hypothesis Testing

### Research Question

Is movie popularity associated with average movie rating?

### Hypotheses

**H₀:** There is no monotonic relationship between movie popularity and average rating.

**H₁:** There is a monotonic relationship between movie popularity and average rating.

A **Spearman rank correlation test** was used because popularity was highly skewed and contained extreme values.

Result:

* Spearman's ρ = **0.103**
* p-value = **0.02191**

The result provides evidence of a statistically significant positive association. However, the correlation is very weak, and this does not imply that popularity causes higher ratings.

## Files

| File                | Description                             |
| ------------------- | --------------------------------------- |
| `movies_raw.csv`    | Collected and cleaned movie dataset     |
| `network_edges.csv` | Movie–actor/director network data       |
| `data_collection.R` | R code for collecting and cleaning data |
| `hypothesis_test.R` | R code for the hypothesis test          |

## Packages

The data collection code uses:

```r
library(httr2)
```

## Limitations

* The dataset contains 494 movies after cleaning.
* Only the first 10 credited actors were collected for each movie.
* Network relationships are limited to movie–actor and movie–director relationships.
* TMDb popularity and rating values are platform-specific measures.
* The correlation analysis identifies association, not causation.
