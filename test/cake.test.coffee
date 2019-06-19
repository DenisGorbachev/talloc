{MongoClient} = require('mongodb');

describe 'Cake factory', ->
  connection = null
  db = null

  beforeAll ->
    connection = await MongoClient.connect(global.__MONGO_URI__, {useNewUrlParser: true})
    db = await connection.db(global.__MONGO_DB_NAME__)

  afterAll ->
    await connection.close()
    await db.close()

  System = {
    run: ->
    BakeCake: ->
      Users = db.collection('Users')
      cook = await Users.findOne({roles: ['Cook']})

      Artefacts = db.collection('Artefacts');
      flour = await Artefacts.findOne({type: 'Flour', amount: 500})
      eggs = await Artefacts.findOne({type: 'Eggs', amount: 5})
      water = await Artefacts.findOne({type: 'Water', amount: 1000})

      # TODO: wait for 5 hours

      # TODO: wrap in transaction
      await Artefacts.remove(flour._id)
      await Artefacts.remove(eggs._id)
      await Artefacts.remove(water._id)
      await Artefacts.insert({type: 'Cake'})
  }

  it 'should schedule a task for baking the cake', ->
    Users = db.collection('Users')
    await Users.insert({roles: ['Cook']})
    await Users.insert({roles: ['Helper']})

    Artefacts = db.collection('Artefacts');
    await Artefacts.insert({type: 'Flour', amount: 1000})
    await Artefacts.insert({type: 'Eggs', amount: 10})
    await Artefacts.insert({type: 'Water', amount: 5000})

    System.run()

    Tasks = db.collection('Tasks');
    tasks = await Tasks.find().toArray()
    expect(tasks).to.deep.equal([
      {type: 'SplitArtefact', context: {type: 'Flour', 500}}
      {type: 'SplitArtefact', context: {type: 'Eggs', 5}}
      {type: 'SplitArtefact', context: {type: 'Water', 1000}}
    ])

    # TODO: simulate execution of current tasks

    System.run()

    Tasks = db.collection('Tasks');
    tasks = await Tasks.find().toArray()
    expect(tasks).to.deep.equal([
      {type: 'BakeCake'}
    ])

  it 'should schedule a task for fetching flour', ->
    Users = db.collection('Users');
    await Users.insert({roles: ['Cook']})

    Artefacts = db.collection('Artefacts');
    # no flour
    await Artefacts.insert({type: 'Eggs', amount: 10})
    await Artefacts.insert({type: 'Water', amount: 5000})

    System.run()

    Tasks = db.collection('Tasks');
    tasks = await Tasks.find().toArray()
    expect(tasks).to.deep.equal([
      {type: 'FetchFlour', context: {amount: 500}}
    ])

  # Jest requires `describe` callback not to return any value
  return undefined
