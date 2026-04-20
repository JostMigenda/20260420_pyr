# install.packages("bench")


### Using built-in functions

numbers <- runif(100000)

manualSum <- function(numbers) {
  total <- 0
  for(i in 1:length(numbers)) {
    total <- total + numbers[i]
  }
  return(total)
}

builtinSum <- function(numbers){
  return(sum(numbers))
}

bench::mark(
  manualSum(numbers),
  builtinSum(numbers),
)[c("expression", "min", "median", "itr/sec")]

# The built-in sum function is about 20 times faster:
# 
#   expression                min   median `itr/sec`
#   <bch:expr>           <bch:tm> <bch:tm>     <dbl>
# 1 sum_manual(numbers)    1.26ms   1.35ms      725.
# 2 sum_builtin(numbers)  72.98µs  73.23µs    13142.




### Growing data frames row-by-row is slow


df_appending <- function(nrows) {
  # Allocate a data.frame with 3 columns
  df <- data.frame(x = numeric(), y = numeric(), z = numeric())

  # Append rows one by one
  for (i in 1:nrows) {
    new_row <- data.frame(x = i, y = i * 2, z = i * 3)
    df <- rbind(df, new_row)
  }
}

df_preallocate <- function(nrows) {
  # Allocate a data.frame with 3 columns and preallocate rows.
  df <- data.frame(x = numeric(nrows), y = numeric(nrows), z = numeric(nrows))

  # Fill in rows
  for (i in 1:nrows) {
    df$x[i] <- i
    df$y[i] <- i * 2
    df$z[i] <- i * 3
  }
}

nrows <- 10000
bench::mark(
  df_appending(nrows),
  df_preallocate(nrows),
)[c("expression", "min", "median", "itr/sec")]

# Preallocating is about 6 times faster:
#
#   expression                 min   median `itr/sec`
#   <bch:expr>            <bch:tm> <bch:tm>     <dbl>
# 1 df_appending(nrows)      2.17s    2.17s     0.461
# 2 df_preallocate(nrows) 318.47ms 319.55ms     3.13 

# Alternatives:
# dplyr::bind_rows / dplyr::mutate
# data.table package (https://r-datatable.com)

# Example from https://sig-rpc.github.io/optimisation/r/dont-grow-dataframes/




### Data types: use hashing data structures for existence checking or uniqueness

vect10k <- as.character(1:10000)
vect1M <- as.character(1:1000000)

nl10k <- as.list(vect10k)
names(nl10k) <- as.character(vect10k)

nl1M <- as.list(vect1M)
names(nl1M) <- vect1M

env10k <- new.env()
for(i in 1:10000) {
  env10k[[as.character(i)]] <- NULL
}

env1M <- new.env()
for(i in 1:1000000) {
  env1M[[as.character(i)]] <- NULL
}

bench::mark(
  "789" %in% vect10k,
  "789" %in% vect1M,
  !is.null(nl10k[["789"]]),
  !is.null(nl1M[["789"]]),
  exists("789", env10k),
  exists("789", env1M),
)[c("expression", "min", "median", "itr/sec")]

# Checking whether an entry is contained in a *vector* is slow and becomes even
# slower proportional to the vector length. Checking a *named lists* is fairly
# slow, but independent of the number of list entries. Using an *environment* is
# about 10 times faster and independent of the number of entries. However, since
# environments aren’t typically used like this, the code may be harder to
# understand for others.
# Possible alternative: https://cran.r-project.org/web/packages/hash/refman/hash.html

#   expression                        min   median `itr/sec`
#   <bch:expr>                   <bch:tm> <bch:tm>     <dbl>
# 1 "\"789\" %in% vect10k"          3.4µs   6.81µs   134001.
# 2 "\"789\" %in% vect1M"        422.79µs 491.18µs     1978.
# 3 "!is.null(nl10k[[\"789\"]])"   6.07µs   6.19µs   157695.
# 4 "!is.null(nl1M[[\"789\"]])"    6.07µs   6.19µs   155921.
# 5 "exists(\"789\", env10k)"    410.01ns 491.97ns  1894383.
# 6 "exists(\"789\", env1M)"     410.01ns 492.09ns  1846079.



### Vectorisation (1)

vector10 <- runif(10, -1, 1)
vector100 <- runif(100, -1, 1)
vector1k <- runif(1000, -1, 1)
vector10k <- runif(10000, -1, 1)

cutoff_for <- function(numbers){
  for(i in 1:length(numbers)){
    if(numbers[i] < 0) {
      numbers[i] <- 0
    }
  }
  return(numbers)
}

cutoff_vectorised <- function(numbers){
  numbers[numbers < 0] <- 0
  return(numbers)
}

bench::mark(
  cutoff_for(vector10),
  cutoff_for(vector100),
  cutoff_for(vector1k),
  cutoff_for(vector10k),
  cutoff_vectorised(vector10),
  cutoff_vectorised(vector100),
  cutoff_vectorised(vector1k),
  cutoff_vectorised(vector10k),
  check = FALSE)[c("expression", "min", "median", "itr/sec")]




### Vectorisation (2)
# Example code from https://adv-r.hadley.nz/perf-improve.html (CC-BY-NC-SA 4.0)

lookup <- setNames(as.list(sample(100, 26)), letters)

x1 <- "j"
x10 <- sample(letters, 10)
x100 <- sample(letters, 100, replace = TRUE)
x1k <- sample(letters, 1000, replace = TRUE)
x10k <- sample(letters, 10000, replace = TRUE)

bench::mark(
  lookup[x1],
  lookup[x10],
  lookup[x100],
  lookup[x1k],
  lookup[x10k],
  check = FALSE
)[c("expression", "min", "median", "itr/sec")]