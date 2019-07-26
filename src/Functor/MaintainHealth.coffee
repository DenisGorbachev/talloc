import _ from 'lodash'
import Joi from '@hapi/joi'
import Functor from '../Functor'

export default class MaintainHealth extends Functor
  constructor: (opts, deps) ->
    super(Joi.attempt(opts, Joi.object().keys({
    ### no params ###
    })), deps)
  execute: (user) ->
    exercise = await @db.Acts.findOne(
      type: 'MorningExercise'
      userId: user._id
      createdAt: { $gte: @moment().subtract(1, 'day').toDate() }
    )
    if !exercise
      @add('CreateAct'
        title: "Do morning exercises"
        blueprint:
          type: 'MorningExercise'
          userId: user._id
      )
    else
      undefined
