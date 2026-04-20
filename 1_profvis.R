# install.packages("profvis")
library(profvis)

a_1 <- function() {
  for(i in 1:3){
    b_1()
  }
  pause(1)
  b_2()
}

b_1 <- function() {
  c_1()
  c_2()
}

b_2 <- function() {
  pause(1)
}

c_1 <- function() {
  pause(0.5)
}

c_2 <- function() {
  pause(0.3)
  d_1()
}

d_1 <- function() {
  pause(0.1)
}

# Profile with `profvis(a_1())`
