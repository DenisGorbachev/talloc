{MongoClient} = require('mongodb');
sum = require('../lib/sum');

describe 'Cake factory', ->
  connection = null
  db = null

  beforeAll ->
    connection = await MongoClient.connect(global.__MONGO_URI__, {
      useNewUrlParser: true,
    });
    db = await connection.db(global.__MONGO_DB_NAME__);

  afterAll ->
    await connection.close();
    await db.close();

  it 'should schedule a task for baking the cake', ->
    Users = db.collection('Users');
    await Users.insert({roles: ['Cook']})

    Artefacts = db.collection('Artefacts');
    await Artefacts.insert({type: 'Flour', amount: 1000})
    await Artefacts.insert({type: 'Eggs', amount: 10})
    await Artefacts.insert({type: 'Water', amount: 5000})

    System = {
      run: ->
    }
    System.run()
    Tasks = db.collection('Tasks');
    tasks = await Tasks.find().toArray()
    expect(tasks.length).toBe(1)

  # Jest requires `describe` callback not to return any value
  return undefined
