# COMP3020 Social Web Analytics
# Hypothesis Testing
# Person 1

# Research Question:
# Is movie popularity associated with average movie rating?

# H0:
# There is no monotonic relationship between popularity and average rating.

# H1:
# There is a monotonic relationship between popularity and average rating.

# Spearman correlation test
result <- cor.test(
  movies$popularity,
  movies$vote_average,
  method = "spearman",
  exact = FALSE
)

result