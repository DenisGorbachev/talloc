# Install

```bash
git clone $REPO_URL $PROJECT_DIR
cd $PROJECT_DIR
yarn install
yarn test
```

# Vision

Goal: maximize production
Goal (precise): maximize count of new objects over time period under the following conditions: objects must pass validation, time period is static
Transformation:
    Input: world state + available transformations
    Output: messages for actors
- Different starting parameters of each actor
- Changing environment

# Architecture

* Should we use Errors to create tasks? (?)
  = But we won't be able to pull multiple tasks for different actors
    = But do we need that?
* Functions or Functors? (Functors)
  = Functors support context
    = Functions can accept `context` as last argument
    = Functions can accept `context` via .apply() 
  = Functors support multiple calls
  = Functors support states (may be necessary, may be not)
  = Functors support "blueprinting" via inheritance (e.g. SendAirdropMessage extends SendMessage)
  = Functors support simple helper calls via inheritance (no need to import them)
* What to return from materializers? (null + run manually)
  ~ Blueprints
    = But may not be able to return full objects due to validation
    = But will have to generate tasks in parent functor
  ~ Tasks or Objects
  ~ null + execute tasks manually
    = And may be better flow control
    = And explicit
