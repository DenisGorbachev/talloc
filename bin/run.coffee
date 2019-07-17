#!/usr/bin/env coffee

import Reproduce from '../lib/Functor/Reproduce'
import {display} from '../lib/helpers'

run = ->
  ###
    ~ Distribute tasks via general planning approach
      # Notes
        * Does not allow to take individual skills / motivations into account
      * Generate a task tree
      * Assign leaf tasks to actors
    ~ Distribute tasks via personal selection approach
      * for user in db.Users.find()
        * Get task
        * Send a message
          - Channel: user-system direct
          - Validations:
            - Motivates the user to perform transformation
  ###
  for user in await db.Users.find().fetch()
#    reproduce = new Reproduce(user: user)
#    results = reproduce.execute()
    send([
      {
        type: 'SendMessage'
      }
    ])


###
  * Generally, function is a reaction: multiple inputs, multiple actors, multiple outputs
  * Should we treat actors as inputs?
    * And corresponds with storing users in DB
    *
###
