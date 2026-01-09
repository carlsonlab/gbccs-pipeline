## How we will code when working on this project
### AUTHOR: Cole
### DATE: 04 January 2026

There are a handful of things that we can agree on to make the code base that lives here slightly more inter-operable and easy to use. In general, we use the a flexible style guide, with the following general statements to keep everyone working similarly: 

1. Functions should be named with camel case (i.e. `myFunction`) and variables should be named with snake case (i.e. `my_variable`). Functions should also be documented using `Roxygen` style documentation
2. Every function doesn't need it's own file, but each "task" or "function family" should have it's own file. That is, a central function and any unique helpers should all be in one file 
3. We use package forcing in most cases, with exceptions being for base functions, and for `ggplot2`.Example: 
    GOOD: `dplyr::filter(variable == "yes"))`
4. Base R pipes are preferred over `magrittr` pipes to minimize dependencies, but `magrittr` dependencies are completely acceptable when needed 
5. Each function should have minimal test cases for whatever level of flexibility it's required to have. If the function is only ever used for it's example usage, having a single test or two in the docstring is sufficient. If it's a flexible function that needs to work across the whole code base, consider writing a more expansive test suite