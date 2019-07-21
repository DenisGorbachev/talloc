import _ from 'lodash';
import Joi from '@hapi/joi'

export default class Functor
  constructor: (opts, deps) ->
    _.extend(@, Joi.attempt(opts, Joi.object()))
    _.extend(@, Joi.attempt(deps, Joi.object()))
    @tasks = []
  add: (type, context, priority = 10) ->
    task = { type, context, priority, genome: [] }
    @tasks.push(task)
    task
  addText: (text, context, priority = 100) ->
    @add('Execute', Object.assign({ text }, context), priority)
  assign: (genome) ->
    for task in @tasks
      task.genome = task.genome.concat(genome)
  getOne: (collection, query, options = {}) ->
    results = @get(collection, query, Object.assign(options, { limit: 1 }))
    results[0]
  create: (collection, query, options = {}) ->
    plans = @plan(collection, query, options)
    plan = _.minBy(plans, 'time')
  plan: (collection, query, options = {}) ->
    _.flatten(
      for functorClass in Functor.endpoints[collection] || []
        functor = new functorClass()
        functor.plan(collection, query, options)
    )
  get: (collection, query, options = {}) ->
    functorClasses = Functor.endpoints[collection] || []
    functors =
      for functorClass in functorClasses
        functor = new functorClass()
        time = functor.estimate(collection, query, options)
        { functor, time }
    if !functors.length then throw new Error("Can't find functor for #{JSON.stringify({
      collection,
      query,
      options
    }, 2)}")
    { functor, time } = _.minBy(functors, 'time')
    results = functor.execute(collection, query, options)
    @tasks = @tasks.concat(functor.tasks)
    results
  find: (collection, query, options = {}) ->
    throw new Error("Replace with #{collection}.find()")
  estimate: (collection, query, options = {}) ->
# return time
    throw new Error("Implement me")
  execute: (collection, query, options = {}) ->
# return results, leave @tasks on object
    throw new Error("Implement me")
  reexecute: ->
    @tasks = []
    @execute()
  requestToBlueprint: (query, options) ->
    blueprint = {}
    for key, value of query
# flatten structures like {tags: {$all: ['Tag1', 'Tag2']}}
      value = value.$all if value.$all
      blueprint[key] = value
    blueprint

  hours: 60 * 60 * 1000
  @endpoints = {}
  @register: (functorClass, collections) ->
    for collection in collections
      @endpoints[collection] ||= []
      @endpoints[collection].push(functorClass)

