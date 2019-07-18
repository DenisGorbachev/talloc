_ = require('lodash')
moment = require('moment')
{MongoClient} = require('mongodb')

describe 'Cake factory', ->
  it 'temp', ->
  return undefined

###
describe 'Cake factory', ->
  connection = null
  db = null

  beforeAll ->
    connection = await MongoClient.connect(global.__MONGO_URI__, {useNewUrlParser: true})
    db = await connection.db(global.__MONGO_DB_NAME__)
    db.Users = db.collection('Users')
    db.Operations = db.collection('Operations')
    db.Artefacts = db.collection('Artefacts')

  afterAll ->
    await connection.close()
    await db.close()

  System = {
    functors: []

    # tick is in milliseconds
    tick: 0

    now: -> new Date(@tick)

    run: (collection, selector, options) ->
      result = await @fetch(collection, selector, options)
      if result
        result
      else
        plans = @plan(collection, selector, options)
        console.log('plans', plans);
        plan = _.minBy(plans, @estimate.bind(@))
        if plan
          @materialize(plan)
        else
          throw new Error("Can\'t find a plan for #{JSON.stringify({collection, selector, options})}")

    fetch: (collection, selector, options) ->
      result = await db[collection].find(selector, options).toArray()
      # check results' lower bound (aka lower limit, aka min count)
      if options.bound && result.length < options.bound
        return null
      result

    plan: (collection, selector, options) ->
      for functor in @functors
        await functor.plan(collection, selector, options)

    estimate: (plan) ->
      # TODO: sum durations of dependencies
      plan.duration

    materialize: (plan) ->
      console.log('plan', plan);

    simulate: ->
      while (operations = db.Operations.find({finishedAt: null}).toArray()).length
        @tick += 1000
#        for user in db.Users.find({assignedOperationId: null})
#          # assign operation to himself
#          db.Users.find({assignedOperationId: null})
        for operation in operations
          functor = @functors[operation.type]
          functor.execute(operation)
          # creation of new operations & actor assignment runs as hooks for operations
  }

  System.functors.push({
    name: 'SplitArtefact'

    blueprint:
      duration: 100
      probability: 1.0

    plan: (collection, selector, options) ->
      switch collection
        when 'Artefacts'
          if selector.type && selector.amount
            srcArtefact = await db.Artefacts.findOne({type: selector.type, amount: {$gt: selector.amount}})
            if srcArtefact
              Object.assign({name: @name}, @blueprint, {context: {artefactId: srcArtefact._id}})

    execute: (operation) ->
      if System.now() - operation.startedAt.getTime() > @blueprint.duration
        oldArtefact = await db.Artefacts.findOne({_id: operation.context.artefactId})
        newArtefact = _.cloneDeep(oldArtefact)
        newArtefact.context.amount = operation.context.amount
        result = await db.Artefacts.updateOne({_id: operation.context.artefactId}, {$set: {'context.amount': oldArtefact.context.amount - operation.context.amount}})
        result = await db.Artefacts.insertOne(_.merge(oldArtefact, {amount: operation.context.amount}))
        await db.Operations.updateOne({_id: operation._id}, {$set: {result: result}})
      else
        operation # nothing happens
  })

  System.functors.push({
    name: 'BakeCake'

    blueprint:
      duration: 4 * 60 * 60 * 1000
      probability: 1.0

    plan: (collection, selector, options) ->
      switch collection
        when 'Artefacts'
          if selector.type is 'Cake'
            Object.assign({name: @name}, @blueprint)

    execute: (operation) ->
      cook = await db.Users.findOne({roles: ['Cook']})

      Artefacts = db.collection('Artefacts');
      flour = await Artefacts.findOne({type: 'Flour', amount: 500})
      eggs = await Artefacts.findOne({type: 'Eggs', amount: 5})
      water = await Artefacts.findOne({type: 'Water', amount: 1000})

      # TODO: wait for 5 hours

      # TODO: wrap in transaction
      await Artefacts.remove(flour._id)
      await Artefacts.remove(eggs._id)
      await Artefacts.remove(water._id)
      await Artefacts.insertOne({type: 'Cake'})

  })

  it 'should schedule an operation for baking the cake', ->
    Users = db.collection('Users')
    await Users.insertOne({roles: ['Cook'], createdAt: System.now()})

    System.run('Artefacts', {type: 'Cake'}, {bound: 1})

    Operations = db.collection('Operations')
    operations = await Operations.find().toArray()
    expect(operations).toBe([
      {type: 'BakeCake'}
    ])

  it 'should schedule an operation for baking the cake by splitting ingredients', ->
    Users = db.collection('Users')
    await Users.insertOne({roles: ['Cook'], createdAt: System.now()})
    await Users.insertOne({roles: ['Helper'], createdAt: System.now()})

    Artefacts = db.collection('Artefacts')
    await Artefacts.insertOne({type: 'Flour', amount: 1000, createdAt: System.now()})
    await Artefacts.insertOne({type: 'Eggs', amount: 10, createdAt: System.now()})
    await Artefacts.insertOne({type: 'Water', amount: 5000, createdAt: System.now()})

    System.run('Artefacts', {type: 'Cake'}, {bound: 1})

    Operations = db.collection('Operations')
    operations = await Operations.find().toArray()
    expect(operations).toBe([
      {type: 'SplitArtefact', context: {type: 'Flour', 500}}
#      {type: 'SplitArtefact', context: {type: 'Eggs', 5}}
#      {type: 'SplitArtefact', context: {type: 'Water', 1000}}
    ])

    # TODO: simulate execution of current operations

    System.run()

    Operations = db.collection('Operations')
    operations = await Operations.find().toArray()
    expect(operations).toBe([
      {type: 'BakeCake'}
    ])

  it 'should schedule an operation for fetching flour', ->
    Users = db.collection('Users');
    await Users.insertOne({roles: ['Cook']})

    Artefacts = db.collection('Artefacts');
    # no flour
    await Artefacts.insertOne({type: 'Eggs', amount: 10})
    await Artefacts.insertOne({type: 'Water', amount: 5000})

    System.run()

    Operations = db.collection('Operations');
    operations = await Operations.find().toArray()
    expect(operations).toBe([
      {type: 'FetchFlour', context: {amount: 500}}
    ])

  # Jest requires `describe` callback to return undefined
  return undefined
###
